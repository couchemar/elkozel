defmodule Kozel.HTTP.RoomPlayers do

  def init(_transport, _req, []) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["GET"], req, state}
  end

  def malformed_request(req, state) do
    {room, req} = :cowboy_req.binding(:room, req)
    case :gproc.lookup_local_name({:table, room}) do
      :undefined -> {true, req, state}
      _pid -> {false, req, room}
    end
  end

  def content_types_provided(req, state) do
    {[{{"application", "json", :"*"}, :to_json}], req, state}
  end

  def to_json(req, room) do
    players = :gproc.lookup_local_properties(
      {:players,
        :gproc.lookup_local_name({:table, room})})

    json = lc {_, {type, _}} inlist players, do: [type: type]
    {:jsonx.encode(json), req, room}
  end
end