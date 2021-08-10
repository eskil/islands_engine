defmodule IslandsEngine.GameTest do
  use ExUnit.Case, async: true
  alias IslandsEngine.Game
  doctest IslandsEngine.Game, import: true

  describe "game setup" do
    test "starts" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      state = :sys.get_state(pid)
      assert state.player1.name == "player 1"
      assert state.player2.name == nil
      assert state.rules
    end

    test "add player 2" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      state = :sys.get_state(pid)
      assert state.player2.name == "player 2"
    end

    test "player positions an island" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      :ok = Game.position_island(pid, :player1, :square, 1, 1)
      :ok = Game.position_island(pid, :player2, :dot, 10, 10)
    end
  end

  describe "game error operations" do
    test "cannot position island without two players" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :error = Game.position_island(pid, :player2, :square, 1, 1)
    end

    test "cannot position invalid island" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      {:error, :invalid_island_type} = Game.position_island(pid, :player1, :error, 1, 1)
    end

    test "cannot position invalid coordinate" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      {:error, :invalid_coordinate} = Game.position_island(pid, :player1, :square, 10, 10)
    end

    test "cannot add player 3" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      :error = Game.add_player(pid, "player 3")
    end
  end
end
