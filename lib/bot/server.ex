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
    timer = :erlang.send_after(0, self(), :do_join)
    {:ok, BotState.new(table_pid: table_pid,
                       timer_ref: timer)}
  end

  definfo do_join, export: false,
                   state: BotState[timer_ref: timer,
                                   table_pid: table_pid]=state do
    Lager.info "Joining to table #{inspect table_pid}"
    :erlang.cancel_timer(timer)
    token = TS.join(table_pid)
    hand = TS.get_cards(table_pid, token)

    state = state.token(token).hand(hand) |> process_ready
    {:noreply, state}
  end

  defp process_ready(BotState[token: token,
                              table_pid: table_pid]=state) do
    _process_ready TS.ready(table_pid, token), state
  end

  defp _process_ready({:start_round, _round, hand, _table, turns},
                      BotState[token: token,
                               table_pid: table_pid]=state) do
    Lager.info "My turn"
    {_new_hand, _new_table} = TS.turn(table_pid, token, get_card(turns), hand)
    state
  end

  defp _process_ready({:start_round, _round, {:player, _player}, _table}, state) do
    Lager.info "Waiting"
    state
  end

  def get_card([card]) do
    card
  end
  def get_card([card|_]) do
    card
  end

 end
