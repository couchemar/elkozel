defmodule Kozel.Table.Server do
  import GenX.GenServer
  use GenServer.Behaviour

  import Kozel.Cards, only: [ produce_cards: 0,
                              deal: 1,
                              check_hand: 2,
                              available_turns: 2,
                              make_turn: 4,
                              count: 1 ]

  require Lager

  def start_link(), do: :gen_server.start_link(__MODULE__, [], [])

  defrecord TableState, round: 0,
                        decs: [],
                        players_by_token: nil,
                        ids_by_token: nil,
                        tokens_by_id: nil,
                        hands_by_token: nil,
                        next_move: 0,
                        ready: [],
                        table: [],
                        points: {0,0},
                        counters: {0,0}

  def init([]) do
    Lager.info "Initializing table #{inspect self}"
    :random.seed(:os.timestamp)
    {:ok, TableState.new()}
  end

  defcall join, from: from, state: state do
    token = :os.timestamp
    Lager.info "Player #{inspect from} join, got token #{inspect token}"
    {:reply, token, process_join(token, state)}
  end

  defcall get_cards(token), state: TableState[decs: []]=state do
    Lager.info "Player #{inspect token} request cards"
    {h1, h2, h3, h4} = deal(produce_cards)
    {:reply, h1,
     state.hands_by_token(HashDict.new [{token, h1}])
          .decs([h2, h3, h4])}
  end

  defcall get_cards(token), state: TableState[decs: [d|new_decs],
                                              hands_by_token: hands]=state do
    Lager.info "Player #{inspect token} request cards"
    {:reply, d,
     state.hands_by_token(HashDict.put hands, token, d).decs(new_decs)}
  end

  defcall ready(token), from: from,
                        state: TableState[ready: ready,
                                          players_by_token: players]=state do
    Lager.info "Got ready request from #{inspect from}"
    state = state.players_by_token(
        if players == nil do
          HashDict.new [{token, from}]
        else
          HashDict.put players, token, from
        end
    ).ready([token|ready])

    if Enum.count(ready) == 3 do
      state = process_all_ready(state)
    end
    {:noreply, state}
  end

  defcall turn(token, card, hand), state: TableState[hands_by_token: hands,
                                                     ids_by_token: ids,
                                                     table: table]=state do
    Lager.info "Player #{inspect token} turn #{inspect card}. Hand: #{inspect hand}. Table: #{inspect table}"
    case check_hand(card, hand) do
      {:error, error} ->
        {:reply, {:error, error}, state}
      :ok ->
        if hand != HashDict.fetch!(hands, token) do
          {:reply, {:error, "Not your hand"}, state}
        else
          if Enum.member?(available_turns(hand, table), card) do
            {new_hand, new_table} = make_turn(card, hand, HashDict.fetch!(ids, token), table)

            state = state.update_next_move(get_next_move &1)
                         .hands_by_token(HashDict.put(hands, token, new_hand))
                         .table(new_table)
            state = if Enum.count(new_table) < 4 do
                      notify_next_turn(state)
                    else
                      state |> process_round_end |> process_play_end |> process_game_end
                    end
            {:reply, {new_hand, new_table}, state}
          else
            {:reply, {:error, "Unexpected move"}, state}
          end
        end
    end
  end

  def handle_call(msg, from, state) do
    Lager.warning "Got unexpected message #{inspect msg} from #{inspect from} state: #{inspect state}"
    {:reply, {:error, "dont know what you mean"}, state}
  end

  # Private

  defp process_join(token, TableState[ids_by_token: ids,
                                      tokens_by_id: tokens]=state) do
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

    state = state.ids_by_token(ids)
                 .tokens_by_id(tokens)
    if id == 4 do
      state = state.next_move(:random.uniform(4))
    end
    state
  end

  defp process_all_ready(TableState[ready: ready,
                                    tokens_by_id: tokens,
                                    hands_by_token: hands,
                                    players_by_token: players,
                                    next_move: next_move]=state) do
    Lager.info "All ready"
    next_player_token = HashDict.fetch!(tokens, next_move)

    pid = HashDict.fetch!(players, next_player_token)
    hand = HashDict.fetch!(hands, next_player_token)

    table = []
    available_turns = available_turns(hand, table)

    state = state.update_round(&1 + 1)
    Lager.info "Next turn: #{inspect next_player_token} (#{inspect pid})"
    :gen_server.reply(pid, {:start_round, state.round, hand, table, available_turns})
    lc token inlist List.delete(ready, next_player_token) do
      pid = HashDict.fetch!(players, token)
      :gen_server.reply(pid, {:start_round, state.round, {:player, next_move}, table})
    end
    state.table(table)
         .ready([])
  end

  defp notify_next_turn(TableState[round: round,
                                   tokens_by_id: tokens,
                                   hands_by_token: hands,
                                   players_by_token: players,
                                   next_move: next_move,
                                   table: table]=state) do
    Lager.info "Next turn"
    next_player_token = HashDict.fetch!(tokens, next_move)

    {next_pid, _} = HashDict.fetch!(players, next_player_token)
    hand = HashDict.fetch!(hands, next_player_token)

    available_turns = available_turns(hand, table)
    Lager.info "Next turn: #{inspect next_player_token} (#{inspect next_pid})"
    :gen_server.cast(next_pid, {:next_turn, round, hand, table, available_turns})

    lc {pid, _} inlist HashDict.values(players), pid != next_pid do
      :gen_server.cast(pid, {:next_turn, round, {:player, next_move}, table})
    end
    state
  end

  defp process_round_end(TableState[round: round,
                                    players_by_token: players,
                                    table: table]=state) do
    {winner, count} = count(table)
    Lager.info "Round #{round} finished. Winner #{inspect winner} earn #{count} points."
    lc {pid, _} inlist HashDict.values(players) do
      :gen_server.cast(pid, {:round_end, round, {:winner, winner}})
    end
    state = if rem(winner, 2) == 1 do
              state.update_points(fn({p1,p2}) -> {p1+count, p2} end)
            else
              state.update_points(fn({p1,p2}) -> {p1, p2+count} end)
            end
    state.next_move(winner)
  end

  defp process_play_end(TableState[hands_by_token: hands,
                                   players_by_token: players,
                                   points: {p1, p2}=points]=state) do
    if HashDict.values(hands) == [[],[],[],[]] do
      {winner, state} = cond do
        p1 == p2 ->
          {nil, state}
        p1 > p2 ->
          c_up = if p2 >= 30 do 1 else 2 end
          {1, state.update_counters(fn({c1, c2}) -> {c1, c2 + c_up} end)}
        p2 > p1 ->
          c_up = if p1 >= 30 do 1 else 2 end
          {2, state.update_counters(fn({c1, c2}) -> {c1 + c_up, c2} end)}
      end
      Lager.info "Play finished. Winner team #{winner}. Points #{inspect points}. Counters #{inspect state.counters}"
      lc {pid, _} inlist HashDict.values(players) do
        :gen_server.cast(pid, {:play_end,
                               {:winner_team, winner}, {:points, points},
                               {:counters, state.counters}})
      end
      state.round(0).points({0, 0})
    else
      state
    end
  end

  defp process_game_end(TableState[players_by_token: players,
                                   counters: {c1, c2}=counters]=state)
  when c1 >= 6 or c2 >= 6 do
    winner = if c1 > c2 do 2 else 1 end
    Lager.info "Game finished. Winner team #{winner}. Counter #{inspect counters}"
    lc {pid, _} inlist HashDict.values(players) do
      :gen_server.cast(pid, {:game_end, {:winner_team, winner}, {:counters, counters}})
    end
    state
  end
  defp process_game_end(state), do: state

  defp get_next_move(next_move) when next_move == 4, do: 1
  defp get_next_move(next_move), do: next_move + 1

end