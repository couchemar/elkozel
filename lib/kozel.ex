defmodule Kozel.Supervisor do
  use Supervisor.Behaviour

  def start_link() do
    :supervisor.start_link({:local, :kozel_sup}, __MODULE__, [])
  end

  def init([]) do
    supervise children, strategy: :one_for_one
  end

  defp children() do
    [
     supervisor(Kozel.Table.Supervisor, []),
     # TODO: move to separated sup.
     worker(Kozel.Bot.Sentinel, []),
     supervisor(Kozel.Bot.Supervisor, [])
    ]
  end
end

defmodule Kozel do
  use Application.Behaviour

  def start(_type, []) do
    {:ok, _} = Kozel.HTTP.start
    Kozel.Supervisor.start_link
  end


end