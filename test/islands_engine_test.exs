defmodule IslandsEngineTest do
  use ExUnit.Case
  doctest IslandsEngine

  describe "application" do
    test "creates ets table" do
      assert :ets.whereis(:game_state) != :undefined
    end
  end
end
