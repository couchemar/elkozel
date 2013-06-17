defmodule Elkozel do
  use Application.Behaviour

  def start(_type, []) do
    {:ok, _} = Kozel.HTTP.start
    Kozel.Table.Supervisor.start_link()
  end
end