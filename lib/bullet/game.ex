defmodule Kozel.Bullet.Game do
  require Lager
  def init(_transport, req, _opts, _active) do
    {:ok, req, :undefined}
  end

  def stream(data, req, state) do
    Lager.info "Stream! got: #{inspect data}"
    {:reply, "test", req, state}
  end

  def info(data, req, state) do
    Lager.info "Info! got: #{inspect data}"
    {:ok, req, state}
  end
end