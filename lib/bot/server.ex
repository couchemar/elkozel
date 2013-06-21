defmodule Kozel.Bot.Server do
  import GenX.GenServer
  use GenServer.Behaviour

  alias Kozel.Table.Server, as: TS

  require Lager

  def start_link(table_pid) do
    :gen_server.start_link(__MODULE__, table_pid, [])
  end

  defrecord BotState, table_pid: nil,
                      timer_ref: nil,
                      token: nil,
                      hand: nil

  def init(table_pid) do
    Lager.info "Initializing bot #{inspect self}"
    timer = :erlang.send_after(0, self(), :do_init)
    {:ok, BotState.new(table_pid: table_pid,
                       timer_ref: timer)}
  end

  definfo do_init, export: false,
                   state: BotState[timer_ref: timer,
                                   table_pid: table_pid]=state do
    Lager.info "Joining to table #{inspect table_pid}"
    :erlang.cancel_timer(timer)
    token = TS.join(table_pid)

    :gproc.add_local_property {:players, table_pid}, {:bot, token}

    _hand = TS.get_cards(table_pid, token)
    {:noreply, process_ready(state.token(token))}
  end

  defcast next_turn(round, hand, table, turns),
          export: false,
          state: state do
    {:noreply, _process_turn(state, round, hand, table, turns)}
  end

  defcast next_turn(round, {:player, player}, table),
          export: false,
          state: state do
    {:noreply, _process_wait state, round, player, table}
  end

  defcast round_end(round, {:winner, winner}),
          export: false,
          state: state do
    Lager.info "Round #{round} finished. Winner #{winner}"
    {:noreply, process_round_end state}
  end

  defcast play_end({:winner_team, winner},
                   {:points, points},
                   {:counters, counters}),
          export: false,
          state: state do
    Lager.info "Play finished. Winner team #{winner}. Points #{inspect points}. Counters #{inspect counters}"
    case counters do
      {c1, c2} when c1 == 6 or c2 == 6 ->
        {:noreply, state}
      _ ->
        {:noreply, process_play_end state}
    end
  end

  defcast game_end({:winner_team, winner},
                   {:counters, counters}),
          export: false,
          state: state do
    Lager.info "Game finished. Winner team #{winner}. Counters #{inspect counters}"
    {:noreply, state}
  end

  defp process_ready(BotState[token: token,
                              table_pid: table_pid]=state) do
    _process_ready state, TS.ready(table_pid, token)
  end

  defp _process_ready(state, {:start_round, round, hand, table, turns}) do
    _process_turn state, round, hand, table, turns
  end

  defp _process_ready(state, {:start_round, round, {:player, player}, table}) do
    _process_wait state, round, player, table
  end

  def get_card([card|_]) do
    card
  end

  defp _process_turn(BotState[token: token,
                              table_pid: table_pid]=state,
                     round, hand, _table, turns) do
    Lager.info "Round #{round}. My turn"
    {new_hand, _new_table} = TS.turn(table_pid, token, get_card(turns), hand)
    state.hand(new_hand)
  end

  defp _process_wait(state, round, player, _table) do
    Lager.info "Round #{round}. Waiting for player #{player} turn"
    state
  end

  defp process_round_end(BotState[hand: hand] = state) do
    if Enum.count(hand) > 0 do
      process_ready state
    else
      state
    end
  end

  defp process_play_end(BotState[token: token,
                                 table_pid: table_pid] = state) do
    process_ready state.hand(TS.get_cards(table_pid, token))
  end

 end
