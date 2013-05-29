Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Bot.Test do
  use TableCase, async: true

  alias Kozel.Bot.Server, as: BS
  alias Kozel.Table.Test.Client, as: TC

  setup meta do
    table_pid = meta[:table_pid]

    {:ok, bot_pid1} = BS.start_link(table_pid)
    {:ok, bot_pid2} = BS.start_link(table_pid)
    {:ok, bot_pid3} = BS.start_link(table_pid)
    {:ok, hand_pid} = TC.start_link(table_pid, self)

    {:ok, meta ++ [bot_pid1: bot_pid1, bot_pid2: bot_pid2,
                   bot_pid3: bot_pid3, hand_pid: hand_pid]}
  end

  test "game", meta do
    hand_pid = meta[:hand_pid]

    token = TC.join(hand_pid)
    hand = TC.get_cards(hand_pid)

  end
end