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
                      token: nil

  def init([table_pid]) do
    Lager.info "Initializing bot #{inspect self}"
    timer = :erlang.send_after(1000, self(), :do_join)
    {:ok, BotState.new(table_pid: table_pid,
                       timer_ref: timer)}
  end

  definfo do_join, export: false,
                   state: BotState[timer_ref: timer,
                                   table_pid: table_pid]=state do
    Lager.info "Joining to #{inspect table_pid}"
    :erlang.cancel_timer(timer)
    token = TS.join(table_pid)
    {:noreply, state.token(token)}
  end

end
