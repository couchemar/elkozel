defmodule Elkozel.HTTP do
  def start do
    dispatch = [
      {:_, [
        {"/", Elkozel.HTTP.Page, []},
        {"/api/rooms", Elkozel.HTTP.Rooms, []},
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