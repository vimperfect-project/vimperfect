# **Improntant note**: I see no reason in mocking SessionContext as it does not have any
# complex functionality and the SessionContext module is tested itself.
# So, using a mock for SessionContext will only introduce unwanted complixity to the tests
defmodule Vimperfect.Playground.SessionHandlerTest do
  require Logger
  alias Vimperfect.PuzzlesFixtures
  alias Vimperfect.AccountsFixtures
  use Vimperfect.SshCase

  @keys_dir "test/priv/ssh/user"
  @ssh_user "test"
  # Increased timeout to account for nvim startup
  @editor_startup_timeout 1000
  @conn_settings [
    user: @ssh_user,
    auth_methods: "publickey",
    keys_dir: @keys_dir
  ]

  def assert_pty_clear(conn, chan) do
    assert {:ok, data} = SSHClient.collect_response(conn, chan)
    assert data == Vimperfect.Playground.Ssh.TermInfo.Xterm256color.clear()
  end

  defp create_user_with_test_public_key(_) do
    user = AccountsFixtures.user_fixture()

    public_key =
      File.cwd!() |> Path.join([@keys_dir, "/id_ed25519.pub"]) |> File.read!() |> String.trim()

    AccountsFixtures.add_public_key_fixture(user, public_key)

    %{user: user}
  end

  defp create_puzzle(%{user: user}) do
    puzzle = PuzzlesFixtures.puzzle_fixture(user, @ssh_user)

    %{puzzle: puzzle}
  end

  defp create_conn(_) do
    {conn, chan} = ssh_conn(@conn_settings)

    on_exit(fn ->
      SSHClient.close(conn, chan)
    end)

    %{conn: conn, chan: chan}
  end

  describe "Playground with invalid key / connection" do
    test "does not let in with only password auth" do
      opts = Keyword.merge(@conn_settings, auth_methods: "password")

      assert_raise MatchError, fn ->
        ssh_conn(opts)
      end
    end

    test "does not start without a PTY" do
      opts = Keyword.merge(@conn_settings, with_shell: false)
      {conn, chan} = ssh_conn(opts)
      # Manually request the shell
      :ok = SSHClient.request_shell(conn, chan)

      assert {:ok, data} = SSHClient.collect_response(conn, chan)
      assert data == "Sorry, your terminal does not support the required features\n\r"
      assert :closed = SSHClient.collect_response(conn, chan)
    end

    test "sends proper PTY init sequence for xterm-256color" do
      opts = Keyword.merge(@conn_settings, with_pty_init_sequence: false)
      {conn, chan} = ssh_conn(opts)
      term_mod = Vimperfect.Playground.Ssh.TermInfo.Xterm256color

      [:smcup, :smkx, :civis]
      |> Enum.each(fn cmd ->
        {:ok, data} = SSHClient.collect_response(conn, chan)
        assert data == apply(term_mod, cmd, [])
      end)

      assert {:ok, _} = SSHClient.collect_response(conn, chan)
      assert :closed = SSHClient.collect_response(conn, chan)
    end

    test "denies unknown public keys" do
      {conn, chan} = ssh_conn(@conn_settings)
      assert {:ok, data} = SSHClient.collect_response(conn, chan)

      assert data ==
               "Could not find your public key. Make sure you have added it in your profile settings.\n\r"

      assert :closed = SSHClient.collect_response(conn, chan)
    end
  end

  describe "Playground with valid user / connection" do
    setup :create_user_with_test_public_key

    test "does not let with invalid puzzle slug" do
      opts = Keyword.merge(@conn_settings, user: "uknown-slug")
      {conn, chan} = ssh_conn(opts)
      assert {:ok, data} = SSHClient.collect_response(conn, chan)

      assert data ==
               "Could not find the puzzle you are looking for\n\r"

      assert :closed = SSHClient.collect_response(conn, chan)
    end
  end

  describe "Solving a puzzle" do
    setup :create_user_with_test_public_key
    setup :create_puzzle
    setup :create_conn

    test "starts properly with valid client", %{puzzle: puzzle, conn: conn, chan: chan} do
      {:ok, data} =
        SSHClient.collect_all(conn, chan, @editor_startup_timeout)

      # Check that the editor starts properly the nvim instace with the right file contents
      puzzle.initial_content
      |> String.split("\n")
      |> Enum.each(fn line ->
        assert data =~ line
      end)
    end

    test "properly passes with valid solution and does not store if quit without submit", %{
      conn: conn,
      chan: chan
    } do
      # SKip the initial editor draw
      {:ok, resp} = SSHClient.send_keys(conn, chan, "jdd:wq\r")

      assert resp =~ "Congratulations, your solution is correct!"

      # Properly closes after quitting
      {:closed, _} = SSHClient.send_keys(conn, chan, "q")
      # TODO: Check nothing is stored
    end

    # TODO: properly stores the solution if submitted
    # TODO: Properly handles invalid solution and puzzle restart (try first invalid then valid)
  end
end
