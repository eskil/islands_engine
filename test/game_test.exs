defmodule IslandsEngine.GameTest do
  use ExUnit.Case, async: true
  alias IslandsEngine.{Game, Coordinate}
  doctest IslandsEngine.Game, import: true

  setup _cleanup_ets_game_state_between_each_test do
    :ets.delete(:game_state, "player 1")
    :ok
  end

  # This helpers validates that the process and ets state match. This is used in unit tests to ensure
  # that handle_cast/calls properly call reply_success and thereby set the ets state.
  def get_and_check_state(pid, name) do
    process_state = :sys.get_state(pid)
    [{^name, ets_state}] = :ets.lookup(:game_state, name)
    assert process_state == ets_state
    ets_state
  end

  # This test suite tests Game's GenServer behaviour code. This includes
  # testing internal behaviour such as returning timeouts etc.
  describe "game genserver" do
    test "via tuple" do
      assert Game.via_tuple("player 1") == {:via, Registry, {Registry.Game, "player 1"}}
    end

    test "init" do
      {:ok, state} = Game.init("player 1")
      assert Map.keys(state) -- [:player1, :player2, :rules] == []
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

    test "handle timeout" do
      assert Game.handle_info(:timeout, :ok) == {:stop, {:shutdown, :timeout}, :ok}
    end

    test "set state message returns process timeout" do
      {:noreply, state, timeout} = Game.handle_info({:set_state, "player 1"}, %{})
      assert Map.keys(state) -- [:player1, :player2, :rules] == []
      assert is_number(timeout)
      assert timeout > 0
    end

    test "reply success returns timeout" do
      # Note: reply_success is private, but we want to explicitly verify it sets the process timeout
      state = %{player1: %{name: "player 1"}}
      {:reply, :ok, ^state, timeout} = Game.reply_success(state, :ok)
      assert is_number(timeout)
      assert timeout > 0
    end

    test "reply error/1 sets ets state" do
      # Note: reply_error/1 is private, but we want to explicitly verify it sets the process timeout
      state = %{player1: %{name: "player 1"}}
      {:reply, :error, ^state, timeout} = Game.reply_error(state)
      assert is_number(timeout)
      assert timeout > 0
    end

    test "reply error/2 sets ets state" do
      # Note: reply_error/2 is private, but we want to explicitly verify it sets the process timeout
      state = %{player1: %{name: "player 1"}}
      {:reply, {:error, :ok}, ^state, timeout} = Game.reply_error(state, :ok)
      assert is_number(timeout)
      assert timeout > 0
    end
  end

  # This test suite tests Game's management of internal state in ets
  # tables. This tests internal behaviour and implementation details.
  describe "game ets" do
    test "init/terminate adds/removes ets state" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      # TODO: I haven't seen this test fail, but there should be a slight race
      # condition given that the game sends itself a message to set state. If
      # this fails, a small pause here should fix it.
      # Process.sleep(10)
      assert :ets.lookup(:game_state, "player 1") != []
      Game.terminate({:shutdown, :timeout}, :sys.get_state(pid))
      assert :ets.lookup(:game_state, "player 1") == []
    end

    test "set state message sets new state" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      send(pid, {:set_state, "new name"})
      Process.sleep(10)
      assert :ets.lookup(:game_state, "new name") != []
    end

    test "set state message reuses existing state" do
      :ets.insert(:game_state, {"player 1", %{game: "state"}})
      {:ok, _pid} = start_supervised({Game, "player 1"})
      Process.sleep(10)
      assert :ets.lookup(:game_state, "player 1") == [{"player 1", %{game: "state"}}]
    end

    test "reply success sets ets state" do
      # Note: reply_success is private, but we want to explicitly verify it sets the ets state
      state = %{player1: %{name: "player 1"}}
      {:reply, :ok, _state, _timeout} = Game.reply_success(state, :ok)
      [{"player 1", ^state}] = :ets.lookup(:game_state, "player 1")
    end
  end

  # This test suite tests Game setup. This is externally observable behaviour only.
  describe "game setup" do
    test "add player 2" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")
      state = get_and_check_state(pid, "player 1")
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

      state = get_and_check_state(pid, "player 1")
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

      state = get_and_check_state(pid, "player 1")
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

      state = get_and_check_state(pid, "player 1")
      assert state.rules.state == :player1_turn
      assert state.rules.player1 == :islands_set
      assert state.rules.player2 == :islands_set
    end
  end

  # This test suite tests Game's full play. This is externally observable behaviour only.
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

      # Create targets that hit the entire map, except two targets we test
      # separately to test end-of-game
      targets = for row <- Coordinate.board_range, col <- Coordinate.board_range, do: {row, col}
      targets = Enum.reject(targets, fn {row, col} -> {row, col} in [{10, 1}, {10, 10}] end)
      Enum.map(targets, fn {row, col} ->
        {_hit_or_miss, _forested, :no_win} = Game.guess_coordinate(pid, :player1, row, col)
        {_hit_or_miss, _forested, :no_win} = Game.guess_coordinate(pid, :player2, row, col)
      end)

      # Player 1 misses on last row
      {:miss, :none, :no_win} = Game.guess_coordinate(pid, :player1, 10, 1)
      state = get_and_check_state(pid, "player 1")
      assert state.rules.state == :player2_turn

      # Player 2 misses on last row
      {:miss, :none, :no_win} = Game.guess_coordinate(pid, :player2, 10, 1)
      state = get_and_check_state(pid, "player 1")
      assert state.rules.state == :player1_turn

      # Player 1 hits the final island and wins
      {:hit, :dot, :win} = Game.guess_coordinate(pid, :player1, 10, 10)
      state = get_and_check_state(pid, "player 1")
      assert state.rules.state == :game_over

      # Player 2 cannot take a turn
      :error = Game.guess_coordinate(pid, :player2, 10, 10)
    end
  end

  # This test suite tests Game's response to incorrect operations (rule
  # violations). This in part involves internal details such as setting state.
  describe "game error operations" do
    test "cannot position island without two players" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :error = Game.position_island(pid, :player2, :square, 1, 1)
    end

    test "cannot position island when in turn mode" do
      {:ok, pid} = start_supervised({Game, "player 1"})
      :ok = Game.add_player(pid, "player 2")

      # Overwrite the state with one where the rules are already in player1's turn
      state = get_and_check_state(pid, "player 1")
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
      state = get_and_check_state(pid, "player 1")
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
      # Note: this just lets just circumvent all the island setting, but we also
      # have to fiddle with the state, so the ets state won't match.
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
