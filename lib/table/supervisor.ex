defmodule Kozel.Table.Supervisor do
  use Supervisor.Behaviour

  def start_link() do
    :supervisor.start_link({:local, :kozel_table_sup}, __MODULE__, [])
  end

  def start_table() do
    :supervisor.start_child(:kozel_table_sup, [])
  end

  def init([]) do
    children = [ worker(Kozel.Table.Server, []) ]
    supervise children, strategy: :simple_one_for_one
  end

end