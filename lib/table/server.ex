defmodule Kozel.Table.Server do
  use GenServer.Behaviour

  import Kozel.Cards, only: [ produce_cards: 0,
                              deal: 1,
                              check_hand: 2,
                              available_turns: 2,
                              turn: 4 ]

  def start_link() do
    :gen_server.start_link(__MODULE__, [], [])
  end

  defrecord TableState, round: :waiting_joins,
                        decs: [],
                        players_by_token: nil,
                        ids_by_token: nil,
                        tokens_by_id: nil,
                        hands_by_token: nil,
                        next_move: 0,
                        ready: [],
                        table: []

  def init([]) do
    :random.seed(:os.timestamp)
    {h1, h2, h3, h4} = deal(produce_cards)
    {:ok, TableState.new(decs: [h1, h2, h3, h4])}
  end

  def handle_call(:join, _from,
                  TableState[round: :waiting_joins,
                             ids_by_token: ids,
                             tokens_by_id: tokens]=state) do
    token = :os.timestamp

    if ids == nil do
      id = 1
      ids = HashDict.new [{token, id}]
    else
      id = HashDict.size(ids) + 1
      ids = HashDict.put ids, token, id
    end

    if tokens == nil do
      tokens = HashDict.new [{id, token}]
    else
      tokens = HashDict.put tokens, id, token
    end

    new_state = state.ids_by_token(ids)
    new_state = new_state.tokens_by_id(tokens)
    if id == 4 do
      new_state = new_state.next_move(:random.uniform(4))
    end
    {:reply, {:ok, token}, new_state}
  end

  def handle_call({:get_cards, token}, _from,
                  TableState[decs: decs,
                             hands_by_token: hands]=state) when length(decs) > 0 do
    [d|new_decs] = decs
    if hands == nil do
      hands = HashDict.new [{token, d}]
    else
      hands = HashDict.put hands, token, d
    end
    new_state = state.decs(new_decs)
    {:reply, d, new_state.hands_by_token(hands)}
  end

  def handle_call({:ready, token}, from,
                  TableState[ready: ready,
                             players_by_token: players]=state) when length(ready) < 3 do
    if players == nil do
      players = HashDict.new [{token, from}]
    else
      players = HashDict.put players, token, from
    end
    new_state = state.ready([token|ready])
    new_state = new_state.players_by_token(players)
    {:noreply, new_state}
  end

  def handle_call({:ready, token}, from,
                  TableState[ready: ready,
                             players_by_token: players]=state) when length(ready) == 3 do
    if players == nil do
      players = HashDict.new [{token, from}]
    else
      players = HashDict.put players, token, from
    end
    new_state = state.players_by_token(players)
    send_you_turn(new_state)
    {:noreply, new_state.ready([])}
  end

  def handle_call({:turn, token, card, hand}, _from,
                  TableState[hands_by_token: hands,
                             ids_by_token: ids,
                             table: table]=state) do
    case check_hand(card, hand) do
      {:error, error} ->
        {:reply, {:error, error}, state}
      :ok ->
        if hand != HashDict.get!(hands, token) do
          {:reply, {:error, "Not your hand"}, state}
        end

        if List.member?(available_turns(hand, table), card) do
          id = HashDict.get! ids, token
          {new_hand, new_table} = turn(card, hand, id, table)

          new_state = state.update_next_move(get_next_move &1)
          new_state = new_state.hands_by_token(HashDict.put(hands, token, new_hand))
          new_state = new_state.table(new_table)
          send_you_turn(new_state)
          {:reply, {:ok, {new_hand, new_table}}, new_state}
        else
          {:reply, {:error, "Unexpected move"}, state}
        end
    end
  end

  def handle_call(_msg, _from, state) do
    IO.inspect(state)
    {:reply, {:error, "dont know what you mean"}, state}
  end

  # Private

  defp send_you_turn(TableState[tokens_by_id: tokens,
                                hands_by_token: hands,
                                players_by_token: players,
                                next_move: next_move,
                                table: table]) do
    next_player_token = HashDict.get!(tokens, next_move)

    pid = HashDict.get!(players, next_player_token)
    hand = HashDict.get!(hands, next_player_token)

    :gen_server.reply(pid, {:you_turn, hand, table})
  end

  defp get_next_move(next_move) when next_move == 4 do
    1
  end
  defp get_next_move(next_move) do
    next_move + 1
  end

end