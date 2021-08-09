defmodule IslandsEngine.RulesTest do
  use ExUnit.Case, async: true
  alias IslandsEngine.Rules
  doctest IslandsEngine.Rules, import: true

  def fixture(:ready_player1) do
    rules = Rules.new()
    %Rules{rules | state: :player1_turn, player1: :islands_set, player2: :islands_set}
  end

  def fixture(:ready_player2) do
    rules = Rules.new()
    %Rules{rules | state: :player2_turn, player1: :islands_set, player2: :islands_set}
  end

  setup do
    {:ok, [
        ready_player1: fixture(:ready_player1),
        ready_player2: fixture(:ready_player2)
      ]}
  end

  describe "rules games setup" do
    test "starts initialised" do
      rules = Rules.new()
      assert rules.state == :initialised
    end

    test "add player moves to players set" do
      rules = Rules.new()
      assert rules.state == :initialised

      {:ok, rules} = Rules.check(rules, :add_player)
      assert rules.state == :players_set
    end

    test "players positions islands" do
      rules = Rules.new()
      {:ok, rules} = Rules.check(rules, :add_player)

      {:ok, rules} = Rules.check(rules, {:position_island, :player1})
      assert rules.state == :players_set

      {:ok, rules} = Rules.check(rules, {:position_island, :player1})
      assert rules.state == :players_set

      {:ok, rules} = Rules.check(rules, {:position_island, :player2})
      assert rules.state == :players_set

      {:ok, rules} = Rules.check(rules, {:position_island, :player2})
      assert rules.state == :players_set

      assert_raise KeyError, fn ->
        Rules.check(rules, {:position_island, :player3})
      end
    end

    test "players set islands" do
      rules = Rules.new()
      {:ok, rules} = Rules.check(rules, :add_player)
      {:ok, rules} = Rules.check(rules, {:position_island, :player1})
      {:ok, rules} = Rules.check(rules, {:position_island, :player2})

      {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
      assert rules.state == :players_set
      assert rules.player1 == :islands_set
      assert rules.player2 == :islands_not_set

      # It's ok to set islands twice while state remains :players_set
      {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
      assert rules.state == :players_set
      assert rules.player1 == :islands_set
      assert rules.player2 == :islands_not_set

      {:ok, rules} = Rules.check(rules, {:set_islands, :player2})
      assert rules.state == :player1_turn
      assert rules.player1 == :islands_set
      assert rules.player2 == :islands_set
    end

    test "players cannot position islands after set islands" do
      rules = Rules.new()
      {:ok, rules} = Rules.check(rules, :add_player)
      {:ok, rules} = Rules.check(rules, {:position_island, :player1})
      {:ok, rules} = Rules.check(rules, {:position_island, :player2})

      {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
      :error = Rules.check(rules, {:position_island, :player1})

      {:ok, rules} = Rules.check(rules, {:set_islands, :player2})
      :error = Rules.check(rules, {:position_island, :player2})

      assert rules.state == :player1_turn
    end
  end

  describe "rules game play" do
    test "player 1 makes turn", %{ready_player1: rules} do
      {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player1})
      assert rules.state == :player2_turn
    end

    test "player 2 cannot take turn during player 1s turn", %{ready_player1: rules} do
      :error = Rules.check(rules, {:guess_coordinate, :player2})
      assert rules.state == :player1_turn
    end

    test "player 2 makes turn", %{ready_player2: rules} do
      {:ok, rules} = Rules.check(rules, {:guess_coordinate, :player2})
      assert rules.state == :player1_turn
    end

    test "player 1 cannot take turn during player 2s turn", %{ready_player2: rules} do
      :error = Rules.check(rules, {:guess_coordinate, :player1})
      assert rules.state == :player2_turn
    end
  end

  describe "rules game ends" do
    test "player 1 does not win", %{ready_player1: rules} do
      {:ok, rules} = Rules.check(rules, {:win_check, :no_win})
      assert rules.state == :player1_turn
    end

    test "player 1 wins", %{ready_player1: rules} do
      {:ok, rules} = Rules.check(rules, {:win_check, :win})
      assert rules.state == :game_over
    end

    test "player 2 does not win", %{ready_player2: rules} do
      {:ok, rules} = Rules.check(rules, {:win_check, :no_win})
      assert rules.state == :player2_turn
    end

    test "player 2 wins", %{ready_player2: rules} do
      {:ok, rules} = Rules.check(rules, {:win_check, :win})
      assert rules.state == :game_over
    end
  end
end
