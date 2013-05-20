Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Table.Test do
  use ExUnit.Case, async: true

  import Kozel.Table.Server

  setup do
    {:ok, pid} = :gen_server.start_link(Kozel.Table.Server, [], [])
    {:ok, pid: pid}
  end

  test "game", meta do
    server_pid = meta[:pid]

    {:ok, token1} = :gen_server.call(server_pid, :join)
    {:ok, token2} = :gen_server.call(server_pid, :join)
    {:ok, token3} = :gen_server.call(server_pid, :join)
    {:ok, token4} = :gen_server.call(server_pid, :join)

    assert Enum.count(:gen_server.call(server_pid, {:get_cards, token1})) == 8
    assert Enum.count(:gen_server.call(server_pid, {:get_cards, token2})) == 8
    assert Enum.count(:gen_server.call(server_pid, {:get_cards, token3})) == 8
    assert Enum.count(:gen_server.call(server_pid, {:get_cards, token4})) == 8
  end

end