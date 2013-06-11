defmodule Elkozel do
  use Application.Behaviour

  def start(_type, []) do
    {:ok, _} = Elkozel.HTTP.start
    Kozel.Table.Supervisor.start_link()
  end
end