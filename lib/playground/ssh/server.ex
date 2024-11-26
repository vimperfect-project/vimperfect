defmodule Vimperfect.Playground.Ssh.Server do
  @moduledoc """
  Playground server is respponsible for talking to the erlang :ssh application in order to start the playground SSH interface.
  That way all of the SSH logic is hidden behind the `Vimperfect.Playground.Ssh.Server`, `Vimperfect.Playground.Ssh.Authenticator` and `Vimperfect.Playground.Ssh.Cli` modules that all call `:handler` callbacks.

  Required options:
  - `:handler` - a module that implements the `Vimperfect.Playground.Ssh.Handler` behaviour
  - `:system_dir` - a path to the directory that contains the ssh server's system files
  - `:port` - the port to bind the ssh server to
  """

  use GenServer
  require Logger

  # ignores warning about ssh daemon pid being opaque
  @dialyzer {:no_opaque, handle_cast: 2}

  @doc false
  def start_link(opts) do
    GenServer.start_link(
      __MODULE__,
      %{
        pid: nil
      },
      opts
    )
  end

  @doc false
  @spec handle_info(map | any, map) :: {:noreply, map}
  @impl true
  def handle_info(_, state), do: {:noreply, state}

  @impl true
  def init(state) do
    GenServer.cast(self(), :start)
    {:ok, state}
  end

  @impl true
  def handle_cast(:start, state) do
    port = Application.fetch_env!(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:ssh_port)

    system_dir =
      Application.fetch_env!(:vimperfect, Vimperfect.Playground)
      |> Keyword.fetch!(:ssh_system_dir)
      |> String.to_charlist()

    handler =
      Application.fetch_env!(:vimperfect, Vimperfect.Playground) |> Keyword.fetch!(:handler)

    Logger.debug("Using system dir #{inspect(system_dir)} for ssh server")

    start_result =
      :ssh.daemon(port,
        system_dir: system_dir,
        parallel_login: false,
        key_cb: Vimperfect.Playground.Ssh.Authenticator,
        auth_methods: ~c"publickey",
        connectfun: &on_connect(handler, &1, &2, &3),
        disconnectfun: &on_disconnect(handler, &1),
        ssh_cli: {Vimperfect.Playground.Ssh.Cli, handler: handler}
      )

    case start_result do
      {:ok, pid} ->
        Logger.info("SSH server started on port #{port}")
        Process.link(pid)
        {:noreply, %{state | pid: pid}, :hibernate}

      {:error, :eaddrinuse} ->
        :ok = Logger.error("Unable to bind to local TCP port; the address is already in use")
        {:stop, :normal, state}

      {:error, err} ->
        Logger.error("Unhandled error encountered: #{inspect(err)}")
        {:stop, :normal, state}
    end
  end

  def on_connect(handler, username, addr, method) do
    handler.on_connect(self(), username, addr, method)
  end

  def on_disconnect(handler, reason) do
    handler.on_disconnect(self(), reason)
  end
end
