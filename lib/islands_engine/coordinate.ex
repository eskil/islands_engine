defmodule IslandsEngine.Coordinate do
  alias __MODULE__

  @enforce_keys [:row, :col]
  defstruct [:row, :col]

  @board_range 1..10
  def board_range, do: @board_range

  @doc """
  ## Examples
    iex> Coordinate.new(1, 1)
    {:ok, %Coordinate{row: 1, col: 1}}

    iex> Coordinate.new(0, 0)
    {:error, :invalid_coordinate}

    iex> Coordinate.new!(1, 1)
    %Coordinate{row: 1, col: 1}

    iex> Coordinate.new!(0, 0)
    ** (ArgumentError) invalid coordinate
  """
  def new(row, col) when row in @board_range and col in @board_range do
    {:ok, %Coordinate{row: row, col: col}}
  end

  def new(_row, _col), do: {:error, :invalid_coordinate}

  def new!(row, col) do
    case new(row, col) do
      {:ok, coordinate} -> coordinate
      {:error, :invalid_coordinate} -> raise(ArgumentError, "invalid coordinate")
    end
  end
end
