defmodule IslandsEngine.GameSupervisorTest do
  use ExUnit.Case, async: true
  alias IslandsEngine.GameSupervisor
  doctest IslandsEngine.GameSupervisor, import: true

  describe "game supervisor" do
    test "init" do
      {:ok, %{strategy: :simple_one_for_one}} = GameSupervisor.init(:ok)
    end

    test "start/stop game" do
      {:ok, game} = GameSupervisor.start_game("king kong")
      assert Process.alive?(game)
      :ok = GameSupervisor.stop_game("king kong")
      assert not Process.alive?(game)
    end
  end
end
