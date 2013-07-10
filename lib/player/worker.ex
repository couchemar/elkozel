defmodule Kozel.Player.Worker do
  import GenX.GenServer
  use GenServer.Behaviour

  alias Kozel.Table.Server, as: TS

  require Lager

  def start_link(table_pid) do
    :gen_server.start_link __MODULE__, table_pid, []
  end

  defrecord PlayerState, table_pid: nil,
                         timer_ref: nil,
                         token: nil,
                         hand: nil

  def init(table_pid) do
    Lager.info "Starting player worker"
    timer = :erlang.send_after(0, self(), :do_init)
    {:ok, PlayerState.new(table_pid: table_pid,
                          timer_ref: timer)}
  end

  definfo do_init, export: false,
                   state: PlayerState[timer_ref: timer,
                                      table_pid: table_pid]=state do
    Lager.info "Joining to table #{inspect table_pid}"
    :erlang.cancel_timer(timer)
    token = TS.join(table_pid)

    :gproc.add_local_property {:players, table_pid}, {:player, token}

    hand = TS.get_cards(table_pid, token)
    {:noreply, state.token(token).hand(hand)}
  end

end