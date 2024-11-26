defmodule Vimperfect.Playground.Editor.Controls do
  @moduledoc """
  This module contains commands that are executed on the system. Controls track lifetime events of the editor process and forward them to the
  the `monitor_pid` passed to `run_editor/3`.
  """

  @type os_pid() :: non_neg_integer()
  @type path() :: binary()

  @typedoc "Will be called any time there's new output from the editor"
  @type stdout_event :: {:stdout, os_pid(), binary()}
  @typedoc "Will be called when the editor process exits"
  @type exit_event :: {:DOWN, os_pid(), :process, pid(), reason :: any()}

  @doc """
  Used to obtain the editor instance that can be controlled, events will be sent to `monitor_pid`
  """
  @callback run_editor(filepath :: path(), keyspath :: path(), monitor_pid :: pid()) ::
              {:ok, pid(), os_pid()}
              | {:error, any()}

  @callback send_input(exec_pid :: pid(), input :: binary()) ::
              :ok | {:error, any()}

  @doc """
    Used to run the editor in headless mode by executing commands from the keypath
  """
  @callback run_headless_emulation(filepath :: path(), keyspath :: path()) ::
              :ok | {:error, any()}

  @doc """
  Resizing the PTY window size of the editor under `os_pid`
  """
  @callback send_resize(os_pid(), cols :: non_neg_integer(), rows :: non_neg_integer()) ::
              :ok | {:error, any()}

  @doc """
  Used to stop a running process gracefully (with sending a termination message in case the app does not respond)

  Note: when calling `force_stop/2`, the default exit message will be sent to `monitor_pid` that was set in `run_editor/3`
  """
  @callback force_stop(exec_pid :: pid(), os_pid :: non_neg_integer()) :: :ok | {:error, any()}

  @doc """
  Creates `{root_dir}/{session_name}` directory if not exists and creates to files inside:
  - filepath: path to the file that will be opened by the editor, this file will store the content
  - keyspath: path to the file that will be used to log keystrokes for later processing, by default is empty
  """
  @callback prepare_dir(
              root_dir :: path(),
              session_name :: binary(),
              filename :: binary(),
              file_content :: binary()
            ) ::
              {:ok, filepath :: path(), keyspath :: path()} | {:error, any()}

  @doc """
  Used to remove the directory that was created by `prepare_dir/2`. Should not fail if the directory does not exist.
  """
  @callback clear_dir(root_dir :: path(), session_name :: binary()) ::
              :ok | {:error, any()}
end
