defmodule Vimperfect.Playground.SessionContext do
  @moduledoc false
  alias Vimperfect.Playground.Ssh.Types
  require Logger

  def child_spec(_args) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, []}, type: :worker}
  end

  def start_link do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  @type session :: %{
          required(:peer_address) => Types.peer_address(),
          :auth => Types.public_key_status(),
          puzzle: any(),
          runner_pid: pid() | nil
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

  @spec delete(pid()) :: :ok
  def delete(pid) do
    Agent.update(__MODULE__, &Map.delete(&1, pid))
  end

  @spec find_session(pid()) :: session()
  defp find_session(pid) do
    Agent.get(__MODULE__, &Map.get(&1, pid)) || Map.new()
  end
end
