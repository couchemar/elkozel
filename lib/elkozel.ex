defmodule Elkozel do
  use Application.Behaviour

  def start(_type, []) do
    Kozel.Table.Supervisor.start_link()
  end
end