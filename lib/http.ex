defmodule Kozel.HTTP do
  def start do
    {:ok, _} = :cowboy.start_http(:http, 100,
                                  [port: 9999],
                                  [env: [dispatch: compile_routes]])
  end

  defp static do
    [ directory: {:priv_dir, :elkozel, ["static"]},
      mimetypes: {function(:mimetypes.path_to_mimes/2), :default} ]
  end

  defp compile_routes do
    [
      {:_, [
        {"/", Kozel.HTTP.Page, []},
        {"/template/[:page]", Kozel.HTTP.Page, []},
        {"/api/rooms", Kozel.HTTP.Rooms, []},
        {"/api/rooms/[:room]/bots", Kozel.HTTP.RoomBots, []},
        {"/api/rooms/[:room]/players", Kozel.HTTP.RoomPlayers, []},
        {"/bullet/game", :bullet_handler, [handler: Kozel.Bullet.Game]},
        {"/static/[...]", :cowboy_static, static}
      ]}
    ] |> :cowboy_router.compile
  end

  def update_routes do
    :cowboy.set_env :http, :dispatch, compile_routes
  end
end