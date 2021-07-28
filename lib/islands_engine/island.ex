defmodule IslandsEngine.Island do
  alias __MODULE__
  alias IslandsEngine.Coordinate

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [:coordinates, :hit_coordinates]

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
end
