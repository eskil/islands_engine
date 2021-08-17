defmodule IslandsEngine.GameTest do
  use ExUnit.Case, async: true
  alias IslandsEngine.{Game, Coordinate}
  doctest IslandsEngine.Game, import: true

  describe "game genserver" do
    test "via tuple" do
      assert Game.via_tuple("player 1") == {:via, Registry, {Registry.Game, "player 1"}}
    end

    test "init" do
      {:ok, state, timeout} = Game.init("player 1")
      assert Map.keys(state) == [:player1, :player2, :rules]
      assert is_number(timeout)
      assert timeout > 0
    end

    test "start_link" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      state = :sys.get_state(pid)
      assert state.player1.name == "player 1"
      assert state.player2.name == nil
      assert state.rules
    end

    test "child_spec" do
      child_spec = Game.child_spec("game")
      assert child_spec.restart == :transient
    end

    test "timeout" do
      assert Game.handle_info(:timeout, :ok) == {:stop, {:shutdown, :timeout}, :ok}
    end
  end

  describe "game setup" do
    test "add player 2" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      state = :sys.get_state(pid)
      assert state.player2.name == "player 2"
    end

    test "players positions an island" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      :ok = Game.position_island(pid, :player1, :square, 1, 1)
      :ok = Game.position_island(pid, :player2, :dot, 10, 10)
    end

    test "player can reposition an island" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      :ok = Game.position_island(pid, :player1, :square, 1, 1)
      :ok = Game.position_island(pid, :player1, :square, 1, 2)
    end

    test "players position and sets all islands" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")

      state = :sys.get_state(pid)
      assert state.rules.state == :players_set
      assert state.rules.player1 == :islands_not_set
      assert state.rules.player2 == :islands_not_set

      :ok = Game.position_island(pid, :player1, :square, 1, 1)
      :ok = Game.position_island(pid, :player1, :atoll, 1, 3)
      :ok = Game.position_island(pid, :player1, :l_shape, 3, 1)
      :ok = Game.position_island(pid, :player1, :s_shape, 1, 5)
      :ok = Game.position_island(pid, :player1, :dot, 10, 10)
      :ok = Game.position_island(pid, :player1, :atoll, 1, 3)
      :ok = Game.set_islands(pid, :player1)

      state = :sys.get_state(pid)
      assert state.rules.state == :players_set
      assert state.rules.player1 == :islands_set
      assert state.rules.player2 == :islands_not_set

      :ok = Game.position_island(pid, :player2, :square, 1, 1)
      :ok = Game.position_island(pid, :player2, :atoll, 1, 3)
      :ok = Game.position_island(pid, :player2, :l_shape, 3, 1)
      :ok = Game.position_island(pid, :player2, :s_shape, 1, 5)
      :ok = Game.position_island(pid, :player2, :dot, 10, 10)
      :ok = Game.position_island(pid, :player2, :atoll, 1, 3)
      :ok = Game.set_islands(pid, :player2)

      state = :sys.get_state(pid)
      assert state.rules.state == :player1_turn
      assert state.rules.player1 == :islands_set
      assert state.rules.player2 == :islands_set
    end
  end

  describe "game play" do
    test "full game play" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")

      :ok = Game.position_island(pid, :player1, :square, 1, 1)
      :ok = Game.position_island(pid, :player1, :atoll, 1, 3)
      :ok = Game.position_island(pid, :player1, :l_shape, 3, 1)
      :ok = Game.position_island(pid, :player1, :s_shape, 1, 5)
      :ok = Game.position_island(pid, :player1, :dot, 10, 10)
      :ok = Game.position_island(pid, :player1, :atoll, 1, 3)
      :ok = Game.set_islands(pid, :player1)

      :ok = Game.position_island(pid, :player2, :square, 1, 1)
      :ok = Game.position_island(pid, :player2, :atoll, 1, 3)
      :ok = Game.position_island(pid, :player2, :l_shape, 3, 1)
      :ok = Game.position_island(pid, :player2, :s_shape, 1, 5)
      :ok = Game.position_island(pid, :player2, :dot, 10, 10)
      :ok = Game.position_island(pid, :player2, :atoll, 1, 3)
      :ok = Game.set_islands(pid, :player2)

      # Carpet forest the map, except the three cases we test separately
      targets = for row <- Coordinate.board_range, col <- Coordinate.board_range, do: {row, col}
      targets = Enum.reject(targets, fn {row, col} -> {row, col} in [{10, 1}, {10, 10}] end)
      Enum.map(targets, fn {row, col} ->
        {_hit_or_miss, _forested, :no_win} = Game.guess_coordinate(pid, :player1, row, col)
        {_hit_or_miss, _forested, :no_win} = Game.guess_coordinate(pid, :player2, row, col)
      end)

      # Player 1 misses on last row
      {:miss, :none, :no_win} = Game.guess_coordinate(pid, :player1, 10, 1)
      state = :sys.get_state(pid)
      assert state.rules.state == :player2_turn

      # Player 2 misses on last row
      {:miss, :none, :no_win} = Game.guess_coordinate(pid, :player2, 10, 1)
      state = :sys.get_state(pid)
      assert state.rules.state == :player1_turn

      # Player 1 hits the final island and wins
      {:hit, :dot, :win} = Game.guess_coordinate(pid, :player1, 10, 10)
      state = :sys.get_state(pid)
      assert state.rules.state == :game_over

      # Player 2 cannot take a turn
      :error = Game.guess_coordinate(pid, :player2, 10, 10)
    end
  end

  describe "game error operations" do
    test "cannot position island without two players" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :error = Game.position_island(pid, :player2, :square, 1, 1)
    end

    test "cannot position island when in turn mode" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")

      # Overwrite the state with one where the rules are already in player1's turn
      state = :sys.get_state(pid)
      new_rules = %{state.rules |
                    state: :player1_turn,
                    player1: :islands_set,
                    player2: :islands_set
                   }
      :sys.replace_state(pid, fn state -> %{state| rules: new_rules} end)

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

    test "cannot position on existing islands" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      :ok = Game.position_island(pid, :player1, :square, 1, 1)
      {:error, :overlapping_island} = Game.position_island(pid, :player1, :dot, 1, 1)
    end

    test "cannot set without all positioned" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :error = Game.set_islands(pid, :player1)
      :ok = Game.add_player(pid, "player 2")
      :ok = Game.position_island(pid, :player1, :square, 1, 1)
      :ok = Game.position_island(pid, :player1, :dot, 10, 10)
      {:error, :not_all_islands_positioned} = Game.set_islands(pid, :player1)
    end

    test "cannot set from wrong state" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      # no player2, no islands positioned
      :error = Game.set_islands(pid, :player1)
    end

    test "cannot add player 3" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      :error = Game.add_player(pid, "player 3")
    end

    test "cannot reposition after set" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")

      # Overwrite the state with one where the rules are already in player1's turn
      state = :sys.get_state(pid)
      new_rules = %{state.rules |
                    state: :player1_turn,
                    player1: :islands_set,
                    player2: :islands_set
                   }
      :sys.replace_state(pid, fn state -> %{state| rules: new_rules} end)

      :error = Game.position_island(pid, :player1, :dot, 1, 5)
    end

    test "players cannot go out of turn" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")

      # Overwrite the state with one where the rules are already in player1's turn
      state = :sys.get_state(pid)
      new_rules = %{state.rules |
                    state: :player1_turn,
                    player1: :islands_set,
                    player2: :islands_set
                   }
      :sys.replace_state(pid, fn state -> %{state| rules: new_rules} end)

      # Player1 is up, Player2 cannot play
      state = :sys.get_state(pid)
      assert state.rules.state == :player1_turn
      :error = Game.guess_coordinate(pid, :player2, 1, 1)

      # Player1 is up and guesses...
      {_hit_or_miss, :none, :no_win} = Game.guess_coordinate(pid, :player1, 1, 1)
      # ... Player2 is up then.
      state = :sys.get_state(pid)
      assert state.rules.state == :player2_turn

      # When Player2 is up, Player1 cannot go.
      :error = Game.guess_coordinate(pid, :player1, 1, 1)

      # But Player2 can go
      {_hit_or_miss, :none, :no_win} = Game.guess_coordinate(pid, :player2, 1, 1)

      # Player1 can hit same coordinate if they want...
      {_hit_or_miss, :none, :no_win} = Game.guess_coordinate(pid, :player1, 1, 1)

      # Player2 can go, but cannot hit invalida coordinate
      {:error, :invalid_coordinate} = Game.guess_coordinate(pid, :player2, 0, 0)
    end
  end
end
