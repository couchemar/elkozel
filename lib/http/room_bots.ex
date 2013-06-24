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
      _pid -> {false, req, state}
    end
  end

  def content_types_accepted(req, state) do
    {[{{"application", "json", :"*"}, :from_json}], req, state}
  end

  def from_json(req, state) do
    {:ok, body, req} = :cowboy_req.body(req)
    body = :jsonx.decode body, format: :proplist
    room = ListDict.get body, "room"
    table = :gproc.lookup_local_name {:table, room}
    case Kozel.Bot.Sentinel.start_bot(table) do
      {:ok, _pid} -> {true, req, state}
      {:error, _error} -> {false, req, state}
    end
  end

end