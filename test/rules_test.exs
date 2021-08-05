defmodule IslandsEngine.RulesTest do
  use ExUnit.Case, async: true
  alias IslandsEngine.Rules
  doctest IslandsEngine.Rules, import: true

  def fixture(:ready_player1) do
    rules = Rules.new()
    {:ok, rules} = Rules.check(rules, :add_player)
    {:ok, rules} = Rules.check(rules, {:position_island, :player1})
    {:ok, rules} = Rules.check(rules, {:position_island, :player2})
    {:ok, rules} = Rules.check(rules, {:set_islands, :player1})
    {:ok, rules} = Rules.check(rules, {:set_islands, :player2})
    rules
  end

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

  setup _ready_player1 do
    rules = fixture(:ready_player1)
    {:ok, [rules: rules]}
  end

  test "player 1 makes turn", ready_player1 do
    rules = ready_player1.rules
    IO.puts inspect(rules)
  end
end
