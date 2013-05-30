defmodule Kozel.Bot.Server do
  import GenX.GenServer
  use GenServer.Behaviour

  alias Kozel.Table.Server, as: TS

  require Lager

  def start_link(table_pid) do
    :gen_server.start_link(__MODULE__, [table_pid], [])
  end

  defrecord BotState, table_pid: nil,
                      timer_ref: nil,
                      token: nil,
                      hand: nil

  def init([table_pid]) do
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
    hand = TS.get_cards(table_pid, token)

    {:noreply, process_ready(state.token(token).hand(hand))}
  end

  defcast next_turn(round, hand, table, turns),
          export: false,
          state: state do
    {:noreply, _process_turn(state, round, hand, table, turns)}
  end

  defcast next_turn(round, {:player, player}, table),
          export: false,
          state: state do
    {:noreply, _process_wait(state, round, player, table)}
  end

  defp process_ready(BotState[token: token,
                              table_pid: table_pid]=state) do
    _process_ready TS.ready(table_pid, token), state
  end

  defp _process_ready({:start_round, round, hand, table, turns},
                      state) do
    _process_turn state, round, hand, table, turns
  end

  defp _process_ready({:start_round, round, {:player, player}, table}, state) do
    _process_wait(state, round, player, table)
  end

  def get_card([card]) do
    card
  end
  def get_card([card|_]) do
    card
  end

  defp _process_turn(BotState[token: token,
                              table_pid: table_pid]=state,
                     round, hand, _table, turns) do
    Lager.info "Round #{round}. My turn"
    {_new_hand, _new_table} = TS.turn(table_pid, token, get_card(turns), hand)
    state
  end

  defp _process_wait(state, round, player, table) do
    Lager.info "Round #{round}. Waiting for player #{player} turn"
    state
  end

 end
