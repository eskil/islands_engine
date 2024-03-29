# From https://elixirforum.com/t/assert-a-list-of-patterns-ignoring-order/46068

defmodule ListAssertions do
  defmacro assert_unordered(patterns, expression) when is_list(patterns) do
    clauses =
      patterns
      |> Enum.with_index()
      |> Enum.flat_map(fn {pattern, index} ->
        quote do
          unquote(pattern) -> unquote(index)
        end
      end)

    clauses =
      clauses ++
        quote do
          _ -> :not_found
        end

    quote do
      ListAssertions.__assert_unordered__(
        unquote(Macro.escape(patterns)),
        unquote(expression),
        fn x -> case x, do: unquote(clauses) end
      )
    end
  end

  def __assert_unordered__(patterns, enum, fun) do
    result =
      Enum.reduce(enum, %{}, fn item, acc ->
        case fun.(item) do
          :not_found ->
            raise ArgumentError,
                  "#{inspect(item)} does not match any pattern: #{Macro.to_string(patterns)}"

          index when is_map_key(acc, index) ->
            raise ArgumentError,
                  "both #{inspect(item)} and #{inspect(acc[index])} match pattern: " <>
                    Macro.to_string(Enum.fetch!(patterns, index))

          index when is_integer(index) ->
            Map.put(acc, index, item)
        end
      end)

    if map_size(result) == length(patterns) do
      :ok
    else
      raise ArgumentError,
            "expected enumerable to have #{length(patterns)} entries, got: #{map_size(result)}"
    end
  end
end
