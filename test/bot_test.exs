Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Bot.Test do
  use TableCase, async: true

  alias Kozel.Bot.Server, as: BS

  setup meta do
    table_pid = meta[:table_pid]

    {:ok, pid1} = BS.start_link(table_pid)
    {:ok, pid2} = BS.start_link(table_pid)
    {:ok, pid3} = BS.start_link(table_pid)
    {:ok, pid4} = BS.start_link(table_pid)

    {:ok, meta ++ [pid1: pid1, pid2: pid2,
                   pid1: pid3, pid2: pid4]}
  end

  test "game", meta do
    
  end
end