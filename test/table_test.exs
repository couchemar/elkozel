Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Table.Test do
  use TableCase, async: true

  alias Kozel.Table.Test.Client, as: TC

  defp receive_turn() do
    receive do
      {player, hand, table, turns} ->
        {player, hand, table, turns}
    after
      5000 ->
        flunk "Timeout"
    end
  end

  defp spawn_ready(receiver_pid, client_pid, expected_round) do
    case TC.ready(client_pid) do
      {:start_round, ^expected_round, hand, table, turns} ->
        receiver_pid <- {client_pid, hand, table, turns}
      {:start_round, ^expected_round, {:player, _next_move}, table} ->
        receiver_pid <- {:new_table, table}
    end
  end

  setup meta do
    table_pid = meta[:table_pid]
    {:ok, pid1} = TC.start_link(table_pid, self)
    {:ok, pid2} = TC.start_link(table_pid, self)
    {:ok, pid3} = TC.start_link(table_pid, self)
    {:ok, pid4} = TC.start_link(table_pid, self)

    {:ok, meta ++ [pid1: pid1, pid2: pid2,
                   pid3: pid3, pid4: pid4]}
  end

  defp check_player(players, round, turn) do
    {player, hand, table, available_turns} = receive_turn()
      lc _ inlist Enum.to_list(1..3), do: assert_receive {:new_table, ^table}

      assert Enum.member?(players, player) == true
      players = List.delete(players, player)

      assert Enum.count(hand) == 8 - (round - 1)
      assert Enum.count(table) == turn

      [card|_] = available_turns

      {new_hand, new_table} = TC.turn(player, card)
      assert Enum.count(new_hand) == 7 - (round - 1)
      assert Enum.count(new_table) == turn + 1
      players
  end

  defp check_game_end(test) do
    case test.() do
      {6, _} ->
        :ok
      {_, 6} ->
        :ok
      _ ->
        check_game_end(test)
    end
  end

  test "game", meta do
    pid1 = meta[:pid1]
    pid2 = meta[:pid2]
    pid3 = meta[:pid3]
    pid4 = meta[:pid4]

    token1 = TC.join(pid1)
    token2 = TC.join(pid2)
    token3 = TC.join(pid3)
    token4 = TC.join(pid4)

    assert Enum.count(Enum.uniq([token1, token2, token3, token4])) == 4

    hand1 = TC.get_cards(pid1)
    hand2 = TC.get_cards(pid2)
    hand3 = TC.get_cards(pid3)
    hand4 = TC.get_cards(pid4)

    assert Enum.count(hand1) == 8
    assert Enum.count(hand2) == 8
    assert Enum.count(hand3) == 8
    assert Enum.count(hand4) == 8

    self_pid = self

    lc r inlist Enum.to_list(1..8) do
      players = [pid1, pid2, pid3, pid4]

      lc pid inlist players, do: Process.spawn(fn() -> spawn_ready(self_pid, pid, r) end)

      _check_player = check_player(&1, r, &2)

      assert players |> _check_player.(0) |> _check_player.(1)
                     |> _check_player.(2) |> _check_player.(3) == []

      lc _ inlist Enum.to_list(1..4), do: assert_receive {:round_end, ^r}
    end

    lc _ inlist Enum.to_list(1..4) do
      assert_receive {:play_end, {a, b}, counters}
      assert a + b == 120
      counters
    end

  end
end