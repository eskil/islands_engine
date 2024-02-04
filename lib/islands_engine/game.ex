defmodule IslandsEngine.Game do
  # In test mode, export all so we can test eg. reply_success
  @compile if Mix.env == :test, do: :export_all

  use GenServer, restart: :transient
  alias IslandsEngine.{Board, Guesses, Rules, Island, Coordinate}

  @players [:player1, :player2]
  @timeout 24 * 60 * 60 * 1000 # 1 day

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def init(name) do
    send(self(), {:set_state, name})
    {:ok, fresh_state(name)}
  end

  def terminate({:shutdown, :timeout}, state) do
    :ets.delete(:game_state, state.player1.name)
    :ok
  end

  def terminate(_reason, _state), do: :ok

  def via_tuple(name) do
    {:via, Registry, {Registry.Game, name}}
  end

  defp fresh_state(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    %{player1: player1, player2: player2, rules: %Rules{}}
  end

  def add_player(game, name) when is_binary(name) do
    GenServer.call(game, {:add_player, name})
  end

  def position_island(game, player, key, row, col)  when player in @players do
    GenServer.call(game, {:position_island, player, key, row, col})
  end

  def set_islands(game, player) when player in @players do
    GenServer.call(game, {:set_islands, player})
  end

  def guess_coordinate(game, player, row, col) when player in @players do
    GenServer.call(game, {:guess_coordinate, player, row, col})
  end

  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  def handle_info({:set_state, name}, _state) do
    state = case :ets.lookup(:game_state, name) do
              [] -> fresh_state(name)
              [{_name, state}] -> state
            end
    :ets.insert(:game_state, {name, state})
    {:noreply, state, @timeout}
  end

  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player) do
      state
      |> update_player2_name(name)
      |> update_rules(rules)
      |> reply_success(:ok)
    else
      :error -> reply_error(state)
    end
  end

  def handle_call({:position_island, player, key, row, col}, _from, state) do
    board = player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:position_island, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {:ok, island} <- Island.new(key, coordinate),
           %{} = board <- Board.position_island(board, key, island)
      do
      state
      |> update_board(player, board)
      |> update_rules(rules)
      |> reply_success(:ok)
      else
        :error -> reply_error(state)
      {:error, error} -> reply_error(state, error)
    end
  end

  def handle_call({:set_islands, player}, _from, state) do
    board = player_board(state, player)
    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         true <- Board.all_islands_positioned?(board)
      do
      state
      |> update_rules(rules)
      |> reply_success(:ok)
      else
        :error -> reply_error(state)
      false -> reply_error(state, :not_all_islands_positioned)
    end
  end

  def handle_call({:guess_coordinate, player, row, col}, _from, state) do
    opponent_player = opponent(player)
    opponent_board = player_board(state, opponent_player)
    with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {hit_or_miss, forested_island, win_status, opponent_board} <- Board.guess(opponent_board, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status})
      do
      state
      |> update_board(opponent_player, opponent_board)
      |> update_guesses(player, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> reply_success({hit_or_miss, forested_island, win_status})
      else
        :error -> reply_error(state)
      {:error, error} -> reply_error(state, error)
    end
  end

  defp update_player2_name(state, name), do: put_in(state.player2.name, name)

  defp update_rules(state, rules), do: %{state | rules: rules}

  def reply_success(state, reply) do
    :ets.insert(:game_state, {state.player1.name, state})
    {:reply, reply, state, @timeout}
  end

  def reply_error(state, error), do: {:reply, {:error, error}, state, @timeout}

  def reply_error(state), do: {:reply, :error, state, @timeout}

  defp player_board(state, player), do: Map.get(state, player).board

  defp update_board(state, player, board) do
    Map.update!(state, player, fn player_state ->
      %{player_state | board: board}
    end)
  end

  defp opponent(:player1), do: :player2

  defp opponent(:player2), do: :player1

  defp update_guesses(state, player, hit_or_miss, coordinate) do
    update_in(state[player].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end
end
