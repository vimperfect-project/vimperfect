defmodule Tests.Support.RunnerCallbacks do
  @moduledoc """
  This module contains callbacks that are called by the `DefaultRunner` module.
  """

  @callback on_output(data :: binary()) :: any()
  @callback on_exit(reason :: any()) :: any()
end
