Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Bot.Test do
  use TableCase, async: true

  alias Kozel.Bot.Server, as: BS
  alias Kozel.Table.Test.Client, as: TC

  defp wait_turns do
    receive do
      {:new_table, _table} ->
        wait_turns
      {_pid, _hand, _table, turns} ->
        turns
      data ->
        flunk "Unexpected data: #{inspect data}"
    after
      5000 ->
        flunk "Timeout"
    end
  end

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

    _token = TC.join(hand_pid)
    _hand = TC.get_cards(hand_pid)

    case TC.ready(hand_pid) do
      {:start_round, round, _hand, _table, turns} ->
        [card|_] = turns
        {_new_hand, _new_table} = TC.turn(hand_pid, card)
      {:start_round, round, {:player, _player}, _table} ->
        [card|_] = wait_turns
        {_new_hand, _new_table} = TC.turn(hand_pid, card)
    end

    assert_receive {:round_end, ^round}

  end
end