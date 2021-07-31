defmodule IslandsEngine.BoardTest do
  use ExUnit.Case, async: true
  alias IslandsEngine.{Board, Island, Coordinate}
  doctest IslandsEngine.Board, import: true

  test "position new island without overlap" do
    # test add two islands without overlap
    board = Board.new()
    {:ok, square} = Island.new(:square, Coordinate.new!(1, 1))
    {:ok, dot} = Island.new(:dot, Coordinate.new!(5, 5))
    board = Board.position_island(board, :square, square)
    board = Board.position_island(board, :dot, dot)
    assert Map.keys(board) == [:dot, :square]
  end

  test "position new island with overlap" do
    # test add two islands with overlap
    board = Board.new()
    {:ok, square} = Island.new(:square, Coordinate.new!(1, 1))
    {:ok, dot} = Island.new(:dot, Coordinate.new!(2, 2))
    board = Board.position_island(board, :square, square)
    {:error, :overlapping_island} = Board.position_island(board, :dot, dot)
  end

  test "re-position island without overlap" do
    # test add two islands without overlap
    # then reposition first island without overlap
    board = Board.new()
    {:ok, square} = Island.new(:square, Coordinate.new!(1, 1))
    {:ok, dot} = Island.new(:dot, Coordinate.new!(5, 5))
    board = Board.position_island(board, :square, square)
    board = Board.position_island(board, :dot, dot)
    {:ok, dot} = Island.new(:dot, Coordinate.new!(6, 6))
    board = Board.position_island(board, :dot, dot)
    assert Map.keys(board) == [:dot, :square]
  end

  test "re-position island with overlap" do
    # test add two islands without overlap
    # then reposition first island with overlap
    board = Board.new()
    {:ok, square} = Island.new(:square, Coordinate.new!(1, 1))
    {:ok, dot} = Island.new(:dot, Coordinate.new!(5, 5))
    board = Board.position_island(board, :square, square)
    board = Board.position_island(board, :dot, dot)
    {:ok, dot} = Island.new(:dot, Coordinate.new!(1, 1))
    {:error, :overlapping_island} = Board.position_island(board, :dot, dot)
  end

  test "all islands positioned" do
    # position all islands, check that all_islands_positioned is false until the last
    board = Board.new()
    board = Board.position_island(board, :square, Island.new!(:square, Coordinate.new!(1, 1)))
    assert Board.all_islands_positioned?(board) == false
    board = Board.position_island(board, :atoll, Island.new!(:atoll, Coordinate.new!(1, 3)))
    assert Board.all_islands_positioned?(board) == false
    board = Board.position_island(board, :l_shape, Island.new!(:l_shape, Coordinate.new!(3, 1)))
    assert Board.all_islands_positioned?(board) == false
    board = Board.position_island(board, :s_shape, Island.new!(:s_shape, Coordinate.new!(1, 5)))
    assert Board.all_islands_positioned?(board) == false
    board = Board.position_island(board, :dot, Island.new!(:dot, Coordinate.new!(10, 10)))
    assert Board.all_islands_positioned?(board) == true
  end

  test "hit all islands" do
    # position all islands in the upper part except :dot at 10, 10
    # in two loops (Enum.each(Coordinate.board_range), Board.guess
    # it should be false until the 10, 10th is hit
    board = Board.new()
    board = Board.position_island(board, :square, Island.new!(:square, Coordinate.new!(1, 1)))
    board = Board.position_island(board, :atoll, Island.new!(:atoll, Coordinate.new!(1, 3)))
    board = Board.position_island(board, :l_shape, Island.new!(:l_shape, Coordinate.new!(3, 1)))
    board = Board.position_island(board, :s_shape, Island.new!(:s_shape, Coordinate.new!(1, 5)))
    board = Board.position_island(board, :dot, Island.new!(:dot, Coordinate.new!(10, 10)))
    assert Board.all_islands_positioned?(board) == true

    # 1. Check a hit on the first island, but not forested and no win
    {:hit, :none, :no_win, board} = Board.guess(board, Coordinate.new!(1, 1))

    # Carpet forest the map, except the three cases we test separately
    targets = for row <- Coordinate.board_range, col <- Coordinate.board_range, do: {row, col}
    targets = Enum.reject(targets, fn {row, col} -> {row, col} in [{1, 1}, {10, 9}, {10, 10}] end)
    board = Enum.reduce(targets, board, fn {row, col}, board ->
      {_hit_or_miss, _forested, _win, board} = Board.guess(board, Coordinate.new!(row, col))
      board
    end)

    # 2. Check a miss on the last row
    {:miss, :none, :no_win, board} = Board.guess(board, Coordinate.new!(10, 9))

    # 2. Check a hit and forest on the :dot, and win
    {:hit, :dot, :win, _board} = Board.guess(board, Coordinate.new!(10, 10))
  end
end
