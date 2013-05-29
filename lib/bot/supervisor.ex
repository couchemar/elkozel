defmodule Kozel.Bot.Supervisor do
  use Supervisor.Behaviour

  def start_link() do
    :supervisor.start_link({:local, :kozel_bot_sup}, __MODULE__, [])
  end

  def start_bot(table_pid) do
    :supervisor.start_child(:kozel_bot_sup, [table_pid])
  end

  def init([]) do
    children = [ worker(Kozel.Bot.Server, []) ]
    supervise children, strategy: :simple_one_for_one
  end

end