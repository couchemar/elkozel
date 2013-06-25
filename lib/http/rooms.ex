defmodule Kozel.HTTP.Rooms do
  alias Kozel.Table.Supervisor, as: TS

  require Lager

  def init(_transport, _req, []) do
    IO.puts "init"
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
    tables = :gproc.select([{{:'$1', :'_', :'$2'},
                             [{:'<', :'$2', 5}],
                             [[:'$1', :'$2']]}])

    json = lc [{_, _, {:joined, name}}, joined] inlist tables, do: [name: name, joined: joined]
    Lager.info "#{inspect json}"
    {:jsonx.encode(json), req, state}
  end

  def from_json(req, state) do
    {:ok, _pid} = TS.start_table()
    {true, req, state}
  end

end