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
    # posistion all isladnds, check that all_islands_positioned is false until the last
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

    # Check a hit on the first island, but not forested and no win
    {:hit, :none, :no_win, board} = Board.guess(board, Coordinate.new!(1, 1))

    # Carpet forest the top half...
    board = Enum.reduce(Coordinate.board_range, board, fn col, board ->
      board = Enum.reduce(1..9, board, fn row, board ->
        {hit_or_miss, forested, win, board} = Board.guess(board, Coordinate.new!(row, col))
        IO.puts "row=#{row} col=#{col} #{hit_or_miss} #{forested} #{win}"
        board
      end)
      board
    end)

    # Check a miss on the last row
    {:miss, :none, :no_win, board} = Board.guess(board, Coordinate.new!(10, 1))
    # Check a hit and forest on the :dot
    {:hit, :dot, :win, board} = Board.guess(board, Coordinate.new!(10, 10))

  end
end
