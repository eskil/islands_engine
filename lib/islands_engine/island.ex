defmodule IslandsEngine.Island do
  alias __MODULE__
  alias IslandsEngine.Coordinate

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [:coordinates, :hit_coordinates]

  defp offsets(:square), do: [{0,0}, {0, 1}, {1, 0}, {1, 1}]

  defp offsets(:atoll), do: [{0,0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]

  defp offsets(:dot), do: [{0, 0}]

  defp offsets(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]

  defp offsets(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {1, 1}]

  defp offsets(_), do: {:error, :invalid_island_type}

  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(),
      fn offset, acc ->
        add_coordinate(acc, upper_left, offset)
      end)
  end

  defp add_coordinate(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coordinate} -> {:cont, MapSet.put(coordinates, coordinate)}
      {:error, :invalid_coordinate} -> {:halt, {:error, :invalid_coordinate}}
    end
  end

  @doc """
  ## Examples
    iex> Island.new(:error, Coordinate.new!(1, 1))
    {:error, :invalid_island_type}

    iex> Island.new(:dot, Coordinate.new!(1, 1))
    {:ok, %Island{coordinates: MapSet.new([%Coordinate{col: 1, row: 1}]), hit_coordinates: %MapSet{}}}
  """
  def new(type, %Coordinate{} = upper_left) do
    # The `[_|_] = offsets <- ...` pattern match enforces the returned value
    # is a list. Without this, `offset` could be assigned an error from `offsets/1`,
    # and calling new/2 with an invalid island type would not trigger an error on the
    # first line of `with` statement. Ditto for the `%MapSet{} = coordinates <- ...`
    with [_|_] = offsets <- offsets(type),
         %MapSet{} = coordinates <- add_coordinates(offsets, upper_left)
      do
        {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
      else
        error -> error
    end
  end

  def new!(type, %Coordinate{} = upper_left) do
    case new(type, upper_left) do
      {:ok, island} -> island
      {:error, :invalid_island_type} -> raise(ArgumentError, "Invalid island type")
      {:error, :invalid_coordinate} -> raise(ArgumentError, "Invalid coordinate")
    end
  end

  @doc """
  ## Examples
    iex> Island.overlaps?(Island.new!(:square, Coordinate.new!(1, 1)), Island.new!(:dot, Coordinate.new!(1, 1)))
    true

    iex> Island.overlaps?(Island.new!(:square, Coordinate.new!(1, 1)), Island.new!(:dot, Coordinate.new!(4, 4)))
    false
  """
  def overlaps?(lhs, rhs) do
    not MapSet.disjoint?(lhs.coordinates, rhs.coordinates)
  end

  def guess(%Island{} = island, %Coordinate{} = coordinate) do
    case MapSet.member?(island.coordinates, coordinate) do
      true ->
        hit_coordinates = MapSet.put(island.hit_coordinates, coordinate)
        {:hit, %{island | hit_coordinates: hit_coordinates}}
      false -> :miss
      end
  end
end
