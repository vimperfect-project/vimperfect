defmodule Vimperfect.Playground.SessionContext do
  @moduledoc """
  This module used to store a session context. Session handler can write any fields to here.
  By default a session is an empty map
  """
  alias Vimperfect.Playground.Ssh.Types
  require Logger

  def child_spec(_args) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}, type: :worker}
  end

  def start_link do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  @type session :: %{
          any() => Types.peer_address()
        }

  @spec get(pid()) :: session() | nil
  def get(pid) do
    find_session(pid)
  end

  def set_field(pid, field, value) do
    session = pid |> find_session |> Map.put(field, value)
    :ok = Agent.update(__MODULE__, &Map.put(&1, pid, session))
    session
  end

  def unset_field(pid, field) do
    session = pid |> find_session |> Map.delete(field)
    :ok = Agent.update(__MODULE__, &Map.put(&1, pid, session))
    session
  end

  def field_set?(pid, field) do
    unset =
      pid
      |> find_session
      |> Map.get(field)
      |> is_nil()

    not unset
  end

  @spec delete(pid()) :: session()
  def delete(pid) do
    session = find_session(pid)
    Agent.update(__MODULE__, &Map.delete(&1, pid))
    session
  end

  @doc """
  Returns list of all session pids
  """
  @spec list() :: %{pid() => session()}
  def list() do
    Agent.get(__MODULE__, & &1)
  end

  @spec find_session(pid()) :: session()
  defp find_session(pid) do
    Agent.get(__MODULE__, &Map.get(&1, pid)) || Map.new()
  end
end
