# **Improntant note**: I see no reason in mocking SessionContext as it does not have any
# complex functionality and the SessionContext module is tested itself.
# So, using a mock for SessionContext will only introduce unwanted complixity to the tests
defmodule Vimperfect.Playground.SessionHandlerTest do
  alias Vimperfect.AccountsFixtures
  use Vimperfect.DataCase

  @ip ~c"127.0.0.1"
  @user "play"
  @keys_dir "test/priv/ssh/user"
  @auth_methods "publickey"

  def assert_pty_clear(conn, chan) do
    assert {:ok, data} = SSHClient.collect_response(conn, chan)
    assert data == Vimperfect.Playground.Ssh.TermInfo.Xterm256color.clear()
  end

  defp make_connection(user \\ @user, auth_methods \\ @auth_methods, opts \\ []) do
    user_dir = File.cwd!() |> Path.join(@keys_dir)

    connect_res =
      SSHClient.connect(
        ip: @ip,
        port:
          Application.get_env(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:ssh_port),
        user: user,
        user_dir: user_dir,
        auth_methods: auth_methods
      )

    case connect_res do
      {:ok, conn, chan} ->
        if Keyword.get(opts, :with_shell, true) do
          :ok = SSHClient.request_pty(conn, chan)
          :ok = SSHClient.request_shell(conn, chan)

          if Keyword.get(opts, :skip_pty_init, true) do
            [:smcup, :smkx, :civis]
            |> Enum.each(fn _ ->
              {:ok, _} = SSHClient.collect_response(conn, chan)
            end)
          end
        end

        {conn, chan}

      {:error, reason} ->
        raise reason
    end
  end

  describe "Playground init" do
    test "does not start without a PTY" do
      {conn, chan} = make_connection(@user, @auth_methods, with_shell: false)

      # Manually request the shell
      :ok = SSHClient.request_shell(conn, chan)

      assert {:ok, data} = SSHClient.collect_response(conn, chan)
      assert data == "PTY is required for playground to work\n\r"
      assert :closed = SSHClient.collect_response(conn, chan)
    end

    test "sends proper PTY init sequence for xterm-256color" do
      {conn, chan} = make_connection(@user, @auth_methods, skip_pty_init: false)

      term_mod = Vimperfect.Playground.Ssh.TermInfo.Xterm256color

      [:smcup, :smkx, :civis]
      |> Enum.each(fn cmd ->
        {:ok, data} = SSHClient.collect_response(conn, chan)
        assert data == apply(term_mod, cmd, [])
      end)
    end

    test "denies unknown public keys" do
      {conn, chan} = make_connection()

      assert {:ok, data} = SSHClient.collect_response(conn, chan)

      assert data ==
               "Could not find your public key. Make sure you have added it in your profile settings.\n\r"

      assert :closed = SSHClient.collect_response(conn, chan)
    end

    test "starts and exits properly with valid client" do
      user = AccountsFixtures.user_fixture()

      public_key =
        File.cwd!() |> Path.join([@keys_dir, "/id_ed25519.pub"]) |> File.read!() |> String.trim()

      _user = AccountsFixtures.add_public_key_fixture(user, public_key)

      {conn, chan} = make_connection()

      assert_pty_clear(conn, chan)

      {:ok, data} =
        SSHClient.collect_response(conn, chan)

      assert data == "Welcome to the playground! Press q to quit, e to start editor\n\r"

      # Closes properly on the "q" keypress
      assert :ok = SSHClient.send(conn, chan, "q")
      assert :closed = SSHClient.collect_response(conn, chan)
    end

    test "does not let with unknown user" do
      assert_raise MatchError, fn ->
        make_connection("unknown")
      end
    end

    test "does not let in with only password auth" do
      assert_raise MatchError, fn ->
        make_connection("play", "password")
      end
    end
  end

  # TODO: Check that it started the editor properly
end
