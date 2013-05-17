Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Table.Test do
  use ExUnit.Case, async: true

  import Kozel.Table.Server

  setup do
    {:ok, pid} = :gen_server.start_link(Kozel.Table.Server, [], [])
    {:ok, pid: pid}
  end

  test "get cards", meta do
    server_pid = meta[:pid]

    assert Enum.count(:gen_server.call(server_pid, :get_cards)) == 8
    assert Enum.count(:gen_server.call(server_pid, :get_cards)) == 8
    assert Enum.count(:gen_server.call(server_pid, :get_cards)) == 8
    assert Enum.count(:gen_server.call(server_pid, :get_cards)) == 8
  end

end