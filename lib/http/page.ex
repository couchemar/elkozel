defmodule Kozel.HTTP.Page do

  def init(_transport, req, []) do
    {:ok, req, nil}
  end

  def handle(req, state) do
    {path, req} = :cowboy_req.path(req)
    handle_path(path, req, state)
  end

  def handle_path(_, req, state) do
    {:ok, req} = :cowboy_req.reply(200, [{"content-type","text/html"}],
                                   index_page([]), req)
    {:ok, req, state}
  end

  def terminate(_reason, _req, _state), do: :ok

  require EEx

  EEx.function_from_file :defp, :index_page,
                         Path.expand("../templates/index.html.eex", __FILE__),
                         [:_assigns]
end