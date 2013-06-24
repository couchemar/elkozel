defmodule Kozel.Bot.Sentinel do
  import GenX.GenServer
  use GenServer.Behaviour

  @max_bots 3

  def start_link() do
    :gen_server.start_link({:local, :kozel_bot_sentinel}, __MODULE__, [], [])
  end

  def init(_) do
    {:ok, :undefined}
  end

  defcall start_bot(table_pid), export: :kozel_bot_sentinel,
                                state: state do
    case :gproc.lookup_local_counters({:bots, table_pid}) do
      [] ->
        {:ok, pid} = Kozel.Bot.Supervisor.start_bot(table_pid)
        :gproc.add_local_counter({:bots, table_pid}, 1)
        {:reply, {:ok, pid}, state}
      [{_, bots_count}] when bots_count < @max_bots ->
          {:ok, pid} = Kozel.Bot.Supervisor.start_bot(table_pid)
          :gproc.update_counter({:c, :l, {:bots, table_pid}}, 1)
          {:reply, {:ok, pid}, state};
      [{_, bots_count}] when bots_count >= @max_bots ->
          {:reply, {:error, :bots_limit}, state}
    end
  end
end