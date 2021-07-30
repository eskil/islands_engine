defmodule IslandsEngine.GuessesTest do
  use ExUnit.Case, async: true
  alias IslandsEngine.{Coordinate, Guesses}
  doctest IslandsEngine.Guesses, import: true

  test "guess add" do
    guesses = Guesses.new()

    # Add a hit
    {:ok, hit1} = Coordinate.new(8, 3)
    guesses = Guesses.add(guesses, :hit, hit1)
    assert guesses.hits == MapSet.new([Coordinate.new!(8, 3)])
    assert guesses.misses == MapSet.new([])

    # Add a second hit
    {:ok, hit2} = Coordinate.new(9, 7)
    guesses = Guesses.add(guesses, :hit, hit2)
    assert guesses.hits == MapSet.new([Coordinate.new!(8, 3), Coordinate.new!(9, 7)])
    assert guesses.misses == MapSet.new([])

    # Readd a  hit
    guesses = Guesses.add(guesses, :hit, hit1)
    assert guesses.hits == MapSet.new([Coordinate.new!(8, 3), Coordinate.new!(9, 7)])
    assert guesses.misses == MapSet.new([])

    # Add a miss
    {:ok, miss1} = Coordinate.new(1, 2)
    guesses = Guesses.add(guesses, :miss, miss1)
    assert guesses.hits == MapSet.new([Coordinate.new!(8, 3), Coordinate.new!(9, 7)])
    assert guesses.misses == MapSet.new([Coordinate.new!(1, 2)])

    # Add a second miss
    {:ok, miss2} = Coordinate.new(2, 2)
    guesses = Guesses.add(guesses, :miss, miss2)
    assert guesses.hits == MapSet.new([Coordinate.new!(8, 3), Coordinate.new!(9, 7)])
    assert guesses.misses == MapSet.new([Coordinate.new!(1, 2), Coordinate.new!(2, 2)])
  end
end
