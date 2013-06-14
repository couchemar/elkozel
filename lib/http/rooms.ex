defmodule Elkozel.HTTP.Rooms do

  def init(_transport, _req, []) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["GET", "POST"], req, state}
  end

  def content_types_provided(req, state) do
    {[{{"application", "json", :"*"}, :to_json}], req, state}
  end

  def content_types_accepted(req, state) do
    {[{{"application", "json", :"*"}, :from_json}], req, state}
  end

  def to_json(req, state) do
    json = [[joined: 1],
            [joined: 2],
            [joined: 3]]
    {:jsonx.encode(json), req, state}
  end

  def from_json(req, state) do
    
    {{true, "rooms"}, req, state}
  end

end