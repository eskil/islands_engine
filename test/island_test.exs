defmodule IslandsEngine.IslandTest do
  use ExUnit.Case, async: true
  alias IslandsEngine.Island
  alias IslandsEngine.Coordinate
  doctest IslandsEngine.Island, import: true

  describe "island" do
    test "new" do
      {:ok, island} = Island.new(:dot, Coordinate.new!(10, 10))
      assert island

      {:error, :invalid_island_type} = Island.new(:error, Coordinate.new!(10, 10))
      {:error, :invalid_coordinate} = Island.new(:square, Coordinate.new!(10, 10))
    end

    test "new!" do
      island = Island.new!(:dot, Coordinate.new!(10, 10))
      assert island

      assert_raise ArgumentError, "invalid island type", fn ->
        Island.new!(:ok, Coordinate.new!(10, 10))
      end

      assert_raise ArgumentError, "invalid coordinate", fn ->
        Island.new!(:square, Coordinate.new!(10, 10))
      end
    end

    test "guess a hit" do
      {:ok, island} = Island.new(:square, Coordinate.new!(1, 1))
      {:ok, coordinate} = Coordinate.new(1, 1)

      # Verify a hit and the return value
      {:hit, hit_island} = Island.guess(island, coordinate)
      assert hit_island.hit_coordinates == MapSet.new([coordinate])
    end

    test "guess a miss" do
      {:ok, island} = Island.new(:square, Coordinate.new!(1, 1))
      {:ok, coordinate} = Coordinate.new(8, 8)

      # Verify a miss
      :miss = Island.guess(island, coordinate)
    end

    test "guess a hit and is not forested" do
      {:ok, island} = Island.new(:square, Coordinate.new!(1, 1))
      {:hit, island} = Island.guess(island, Coordinate.new!(1, 1))
      assert Island.forested?(island) == false
    end

    test "guess all hits and is forested" do
      {:ok, island} = Island.new(:square, Coordinate.new!(1, 1))
      {:hit, island} = Island.guess(island, Coordinate.new!(1, 1))
      {:hit, island} = Island.guess(island, Coordinate.new!(1, 2))
      {:hit, island} = Island.guess(island, Coordinate.new!(2, 1))
      {:hit, island} = Island.guess(island, Coordinate.new!(2, 2))
      assert Island.forested?(island) == true
    end
  end
end
