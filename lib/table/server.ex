defmodule Kozel.Table.Server do
  import GenX.GenServer
  use GenServer.Behaviour

  import Kozel.Cards, only: [ produce_cards: 0,
                              deal: 1,
                              check_hand: 2,
                              available_turns: 2,
                              process_turn: 4,
                              count: 1]

  def start_link() do
    :gen_server.start_link(__MODULE__, [], [])
  end

  defrecord TableState, round: 0,
                        decs: [],
                        players_by_token: nil,
                        ids_by_token: nil,
                        tokens_by_id: nil,
                        hands_by_token: nil,
                        next_move: 0,
                        ready: [],
                        table: [],
                        points: {0,0}

  def init([]) do
    :random.seed(:os.timestamp)
    {h1, h2, h3, h4} = deal(produce_cards)
    {:ok, TableState.new(decs: [h1, h2, h3, h4])}
  end

  defcall join, state: TableState[ids_by_token: ids,
                                  tokens_by_id: tokens]=state do
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
    {:reply, token, new_state}
  end

  defcall get_cards(token), state: TableState[decs: decs,
                                              hands_by_token: hands]=state do
    [d|new_decs] = decs
    if hands == nil do
      hands = HashDict.new [{token, d}]
    else
      hands = HashDict.put hands, token, d
    end
    new_state = state.decs(new_decs)
    {:reply, d, new_state.hands_by_token(hands)}
  end

  defcall ready(token), from: from,
                        state: TableState[ready: ready,
                                          players_by_token: players]=state do
    if players == nil do
      players = HashDict.new [{token, from}]
    else
      players = HashDict.put players, token, from
    end
    new_state = state.players_by_token(players)
    new_state = new_state.ready([token|ready])
    if Enum.count(ready) == 3 do
      new_state = new_state.update_round(fn(x) -> x+1 end)
      ready_reply(new_state)
    end
    {:noreply, new_state}
  end

  defcall turn(token, card, hand), state: TableState[hands_by_token: hands,
                                                     ids_by_token: ids,
                                                     table: table]=state do
    case check_hand(card, hand) do
      {:error, error} ->
        {:reply, {:error, error}, state}
      :ok ->
        if hand != HashDict.fetch!(hands, token) do
          {:reply, {:error, "Not your hand"}, state}
        end

        if Enum.member?(available_turns(hand, table), card) do
          id = HashDict.fetch! ids, token
          {new_hand, new_table} = process_turn(card, hand, id, table)

          new_state = state.update_next_move(get_next_move &1)
          new_state = new_state.hands_by_token(HashDict.put(hands, token, new_hand))
          new_state = new_state.table(new_table)
          if Enum.count(new_table) < 4 do
            notify_next_turn(new_state)
          else
            new_state = process_round_end(new_state)
          end
          {:reply, {new_hand, new_table}, new_state}
        else
          {:reply, {:error, "Unexpected move"}, state}
        end
    end
  end

  def handle_call(_msg, _from, state) do
    {:reply, {:error, "dont know what you mean"}, state}
  end

  # Private

  defp ready_reply(TableState[round: round,
                              ready: ready,
                              tokens_by_id: tokens,
                              hands_by_token: hands,
                              players_by_token: players,
                              next_move: next_move,
                              table: table]) do
    next_player_token = HashDict.fetch!(tokens, next_move)

    pid = HashDict.fetch!(players, next_player_token)
    hand = HashDict.fetch!(hands, next_player_token)

    available_turns = available_turns(hand, table)
    :gen_server.reply(pid, {:start_round, round, hand, table, available_turns})
    lc token inlist List.delete(ready, next_player_token) do
      pid = HashDict.fetch!(players, token)
      :gen_server.reply(pid, {:start_round, round, {:player, next_move}, table})
    end
  end

  defp notify_next_turn(TableState[round: round,
                                   tokens_by_id: tokens,
                                   hands_by_token: hands,
                                   players_by_token: players,
                                   next_move: next_move,
                                   table: table]) do

    next_player_token = HashDict.fetch!(tokens, next_move)

    {next_pid, _} = HashDict.fetch!(players, next_player_token)
    hand = HashDict.fetch!(hands, next_player_token)

    available_turns = available_turns(hand, table)
    :gen_server.cast(next_pid, {:next_turn, round, hand, table, available_turns})

    lc {pid, _} inlist HashDict.values(players), pid != next_pid do
      :gen_server.cast(pid, {:next_turn, round, {:player, next_move}, table})
    end

  end

  defp process_round_end(TableState[round: round,
                                    tokens_by_id: tokens,
                                    hands_by_token: hands,
                                    players_by_token: players,
                                    next_move: next_move,
                                    table: table]=state) do
    {winner, count} = count(table)
    state = if rem(winner, 2) == 1 do
              state.update_points(fn({p1,p2}) -> {p1+count, p2} end)
            else
              state.update_points(fn({p1,p2}) -> {p1, p2+count} end)
            end
    state = state.next_move(winner)

    lc {pid, _} inlist HashDict.values(players) do
      :gen_server.cast(pid, {:round_end, round, {:winner, winner}})
    end
    state
  end

  defp get_next_move(next_move) when next_move == 4 do
    1
  end
  defp get_next_move(next_move) do
    next_move + 1
  end

end