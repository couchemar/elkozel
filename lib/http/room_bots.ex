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
    {true, req, state}
  end

end