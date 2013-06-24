defmodule Kozel.HTTP.RoomBots do

  def init(_transport, _req, []) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["POST"], req, state}
  end

  def malformed_request(req, state) do
    {room, req} = :cowboy_req.binding(:room, req)
    case :gproc.lookup_local_name({:table, room}) do
      :undefined -> {true, req, state}
      pid -> {false, req, {room, pid}}
    end
  end

  def forbidden(req, {_room, table_pid}=state) do
    if Kozel.Bot.Sentinel.max_bots?(table_pid) do
      {true, req, state}
    else
      {false, req, state}
    end
  end

  def content_types_accepted(req, state) do
    {[{{"application", "json", :"*"}, :from_json}], req, state}
  end

  def from_json(req, {_room, table_pid}=state) do
    case Kozel.Bot.Sentinel.start_bot(table_pid) do
      {:ok, _pid} -> {true, req, state}
      {:error, _error} -> {false, req, state}
    end
  end
end