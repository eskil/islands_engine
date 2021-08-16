defmodule IslandsEngine.GameSupervisor do
  use DynamicSupervisor

  alias IslandsEngine.Game

  def start_link(_options) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :simple_one_for_one)
  end

  def start_game(name) do
    DynamicSupervisor.start_child(__MODULE__, {Game, name})
  end

  def stop_game(name) do
    DynamicSupervisor.terminate_child(__MODULE__, pid_from_name(name))
  end

  defp pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end
