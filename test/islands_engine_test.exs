defmodule IslandsEngineTest do
  use ExUnit.Case
  alias IslandsEngine.GameSupervisor
  doctest IslandsEngine

  describe "application" do
    test "creates ets table" do
      assert :ets.whereis(:game_state) != :undefined
    end

    test "game supervisor already started" do
      # GameSupervisor is started by IslandsEngine.Application, it'll return an
      # already_started error.
      {:error, {:already_started, _pid}} = start_supervised(GameSupervisor)
    end
end
end
