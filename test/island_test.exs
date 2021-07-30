defmodule IslandsEngine.IslandTest do
  use ExUnit.Case, async: true
  alias IslandsEngine.Island
  alias IslandsEngine.Coordinate
  doctest IslandsEngine.Island, import: true

  test "island guess a hit" do
    {:ok, island} = Island.new(:dot, Coordinate.new!(1, 1))
    {:ok, coordinate} = Coordinate.new(1, 1)

    # Verify a hit and the return value
    {:hit, hit_island} = Island.guess(island, coordinate)
    assert hit_island.hit_coordinates == MapSet.new([coordinate])
  end

  test "island guess a miss" do
    {:ok, island} = Island.new(:dot, Coordinate.new!(1, 1))
    {:ok, coordinate} = Coordinate.new(2, 1)

    # Verify a miss
    :miss = Island.guess(island, coordinate)
  end
end
