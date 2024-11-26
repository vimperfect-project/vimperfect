defmodule Vimperfect.Playground.Editor.RunnerBehaviour do
  @moduledoc """
  A GenServer that allows to control editor process in a separate elixir process by using a module that implements
  `Vimperfect.Playground.Editor.Controls`

  This module talks to editor controls set via `:vimperfect, Vimperfect.Playground.EditorControls` app `:editor_controls` config. In order to process data from the running process,
  it will wait for the `{:stdout, os_pid, data}` event, then it will fire the `on_output/1` callback passed in the `start_link/1` method.

  When a {:DOWN, os_pid, :process, exec_pid, reason} is received, it will kill itself, and upon killing (via GenServer.terminate/2),
  it will call the `on_exit/1` callback.
  """

  @typedoc "Will be called any time there's new output from the editor"
  @type on_output :: (data :: binary() -> any())

  @typedoc "Will be called when the editor process exits"
  @type on_exit :: (reason :: any() -> any())

  @typedoc "Options for the `start_link/1` function."
  @type opts :: %{
          on_output: on_output(),
          on_exit: on_exit()
        }

  @typedoc "Path to the file that will be passed to the editor to edit"
  @type filepath :: binary()

  @typedoc "A path to the file that will be used to store the keystrokes that editor captures"
  @type keyspath :: binary()

  @callback start_link(opts :: opts()) :: {:ok, pid()} | {:error, any()}

  @callback run(runner_pid :: pid(), filepath(), keyspath()) ::
              :ok | {:error, any()}

  @callback alive?(runner_pid :: pid()) :: boolean()

  @callback write(runner_pid :: pid(), data :: binary()) :: :ok

  @callback resize_window(runner_pid :: pid(), cols :: integer(), rows :: integer()) :: :ok

  @callback force_stop(runner_pid :: pid()) :: :ok
end
