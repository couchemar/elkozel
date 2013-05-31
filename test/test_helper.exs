ExUnit.start

defmodule TableCase do
  use ExUnit.CaseTemplate

  setup do
    :application.stop(:lager)
    :application.load(:lager)
    :application.set_env(:lager, :handlers, [])
    :application.set_env(
       :lager, :handlers,
       [lager_console_backend: [
           :debug, {:lager_default_formatter, [:time,' [',:severity,'] | ',:pid,' | ',:message,'\n']}]]
    )
    :application.start(:lager)
    {:ok, table_pid} = :gen_server.start_link(Kozel.Table.Server, [], [])
    {:ok, table_pid: table_pid}
  end
end

defmodule Kozel.Table.Test.Client do
  import GenX.GenServer
  use GenServer.Behaviour

  alias Kozel.Table.Server, as: TS

  defrecord ClientState, table_pid: nil,
                         cast_receiver_pid: nil,
                         token: nil,
                         hand: []

  def start_link(table_pid, cast_receiver_pid) do
    :gen_server.start_link(__MODULE__, [table_pid, cast_receiver_pid], [])
  end

  def init([table_pid, cast_receiver_pid]) do
    {:ok, ClientState.new(table_pid: table_pid,
                          cast_receiver_pid: cast_receiver_pid)}
  end

  defcall join, state: ClientState[table_pid: table_pid]=state do
    token = TS.join(table_pid)
    {:reply, token, state.token(token)}
  end

  defcall get_cards, state: ClientState[table_pid: table_pid,
                                        token: token]=state do
    cards = TS.get_cards(table_pid, token)
    {:reply, cards, state.hand(cards)}
  end

  defcall ready, state: ClientState[table_pid: table_pid,
                                    token: token]=state do
    result = TS.ready(table_pid, token)
    case result do
      {:start_round, _round, hand, _table, _turns} ->
        state = state.hand(hand)
      _ ->
        :ok
    end
    {:reply, result, state}
  end

  defcall turn(card), state: ClientState[table_pid: table_pid,
                                         token: token,
                                         hand: hand]=state do
    {:reply, TS.turn(table_pid, token, card, hand), state}
  end

  def handle_cast({:next_turn, _round, hand, table, available_turns},
                  ClientState[cast_receiver_pid: receiver]=state) do
    state = state.hand(hand)
    receiver <- {self, hand, table, available_turns}
    {:noreply, state}
  end

  def handle_cast({:next_turn, _round, {:player, _next_move}, table},
                  ClientState[cast_receiver_pid: receiver]=state) do
    receiver <- {:new_table, table}
    {:noreply, state}
  end

  def handle_cast({:round_end, round, {:winner, _winner}},
                  ClientState[cast_receiver_pid: receiver]=state) do
    receiver <- {:round_end, round}
    {:noreply, state}
  end

  def handle_cast({:play_end, {:winner_team, _winner},
                              {:points, points}, {:counters, counters}},
                  ClientState[cast_receiver_pid: receiver]=state) do
    receiver <- {:play_end, points, counters}
    {:noreply, state}
  end

  def handle_cast({:game_end, {:winner_team, _winner},
                              {:counters, counters}},
                  ClientState[cast_receiver_pid: receiver]=state) do
    receiver <- {:game_end, counters}
    {:noreply, state}
  end
end