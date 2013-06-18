defmodule Kozel.HTTP do
  def start do
    dispatch = [
      {:_, [
        {"/", Kozel.HTTP.Page, []},
        {"/template/[:page]", Kozel.HTTP.Page, []},
        {"/api/rooms", Kozel.HTTP.Rooms, []},
        {"/api/rooms/[:room]/bots", Kozel.HTTP.RoomBots, []},
        {"/static/[...]", :cowboy_static, static}
      ]}
    ] |> :cowboy_router.compile

    {:ok, _} = :cowboy.start_http(:http, 100,
                                  [port: 9999],
                                  [env: [dispatch: dispatch]])
  end

  defp static do
    [ directory: {:priv_dir, :elkozel, ["static"]},
      mimetypes: {function(:mimetypes.path_to_mimes/2), :default} ]
  end

end