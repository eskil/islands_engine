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
    # Note: Game mustn't do the cleanup in termiante/2, as the process might be
    # crashing and we rely on a restart to pickup the existing state.
    #
    # See also documentation for GenServer.terminate for cases where terminate/2 isn't called.
    # (https://hexdocs.pm/elixir/1.12/GenServer.html#c:terminate/2)
    :ets.delete(:game_state, name)
    DynamicSupervisor.terminate_child(__MODULE__, pid_from_name(name))
  end

  defp pid_from_name(name) do
    name
    |> Game.via_tuple()
    |> GenServer.whereis()
  end
end
