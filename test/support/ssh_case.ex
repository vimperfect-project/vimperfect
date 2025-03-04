defmodule Vimperfect.SshCase do
  @moduledoc """
  This module defines the test case to be used by tests that require restarting SSH server for each test.

  Unlnike `Vimperfect.DataCase` (though it also setups a sandbox), it does not allow async tests, since the server on the speicified port is essentially a singleton.
  The repo is shared between all processes for the running test, and there's a `on_exit/1` callback setup to make sure all of the SSH sessions are killed before each
  test exits and the sandbox owner is stopped.

  After all tests are run, this test will clear all sessions located in the `sessions_dir` (configured in `Vimperfect.Playground`)
  """
  alias Vimperfect.Playground.SessionContext

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Vimperfect.Repo

      import Vimperfect.SshCase
    end
  end

  # TODO: Reset tmp dir
  setup _tags do
    setup_sandbox()
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox() do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Vimperfect.Repo, shared: true)

    on_exit(fn ->
      clear_sessions()
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
    end)

    pid
  end

  defp clear_sessions() do
    sessions = SessionContext.list()

    # Clear the processes
    sessions
    |> Map.keys()
    |> Enum.map(fn pid ->
      ref = Process.monitor(pid)
      Process.exit(pid, :kill)
      ref
    end)
    |> Enum.each(fn ref ->
      receive do
        {:DOWN, ^ref, _, _pid, _} -> :ok
      end
    end)
  end

  def close_ssh_conn(conn, chan) do
    :ssh_connection.close(conn, chan)
    :ok
  end

  @typedoc """
  `ssh_opts` is a keyword list with the following keys:
  - `keys_dir` - The directory where the SSH keys are stored. **Required**.
  - `ip` - The IP address of the SSH server. Defaults to `"127.0.0.1"`.
  - `user` - The user to connect as. Defaults to `"test"`.
  - `auth_methods` - The authentication methods to use. Defaults to `"publickey"`.
  - `with_shell` - Whether to open a shell after connecting. Defaults to `true`.
  - `with_pty_init_sequence` - If the shell is open, `ssh_conn/1` will automatically send the PTY request and if this option is set to `true` it will skip the PTY init sequence.
    It will skip `:smcup`, `:smkx` and `:civis` key codes. Defaults to true. More on that in docs for `Vimperfect.Playground.Ssh.TermInfo`.
  """
  @type ssh_opts :: [
          ip: String.t(),
          user: String.t(),
          keys_dir: String.t(),
          auth_methods: String.t(),
          with_shell: boolean(),
          with_pty_init_sequence: boolean()
        ]

  @doc """
  Connects to the SSH server and returns the connection and channel.

  ### Connection port
  Connection port will be automatically pulled from the `Vimperfect.Playground` configuration `:ssh_port` field.
  """
  @spec ssh_conn(opts :: ssh_opts()) ::
          {:ssh_connection.connection_ref(), :ssh_connection.channel_id()}
  def ssh_conn(opts) do
    user_dir = File.cwd!() |> Path.join(Keyword.fetch!(opts, :keys_dir))

    {:ok, conn, chan} =
      SSHClient.connect(
        ip: Keyword.get(opts, :ip, "127.0.0.1") |> to_charlist(),
        port:
          Application.get_env(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:ssh_port),
        user: Keyword.get(opts, :user, "test") |> to_charlist(),
        user_dir: user_dir |> to_charlist(),
        auth_methods: Keyword.get(opts, :auth_methods, "publickey") |> to_charlist()
      )

    if Keyword.get(opts, :with_shell, true) do
      :ok = SSHClient.request_pty(conn, chan)
      :ok = SSHClient.request_shell(conn, chan)

      if Keyword.get(opts, :with_pty_init_sequence, true) do
        [:smcup, :smkx, :civis]
        |> Enum.each(fn _ ->
          {:ok, _} = SSHClient.collect_response(conn, chan)
        end)
      end
    end

    {conn, chan}
  end
end
