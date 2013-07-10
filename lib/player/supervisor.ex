defmodule Kozel.Player.Supervisor do
  use Supervisor.Behaviour

  def start_link() do
    :supervisor.start_link {:local, :kozel_player_sup}, __MODULE__, []
  end

  def start_player(table_pid) do
    :supervisor.start_child(:kozel_player_sup, [table_pid])
  end

  def init([]) do
    children = [ worker(Kozel.Player.Worker, []) ]
    supervise children, strategy: :simple_one_for_one
  end
end