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

  defp check_game_end(test) do
    case test.() do
      {c1, c2} when c1 >= 6 or c2 >= 6 ->
        :ok
      _ ->
        check_game_end(test)
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

    _check_play = fn() ->
                      _hand = TC.get_cards(hand_pid)
                      lc _ inlist Enum.to_list(1..8) do
                        round = case TC.ready(hand_pid) do
                                  {:start_round, round, _hand, _table, turns} ->
                                    [card|_] = turns
                                    {_new_hand, _new_table} = TC.turn(hand_pid, card)
                                    round
                                  {:start_round, round, {:player, _player}, _table} ->
                                    [card|_] = wait_turns
                                    {_new_hand, _new_table} = TC.turn(hand_pid, card)
                                    round
                                end
                        assert_receive {:round_end, ^round}, 5000
                      end
                      assert_receive {:play_end, {a, b}, counter}, 5000
                      assert a + b == 120
                      counter
                  end

    check_game_end(_check_play)
    assert_receive {:game_end, _counters}

  end
end