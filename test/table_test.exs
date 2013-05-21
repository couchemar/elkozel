Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Table.Test do
  use ExUnit.Case, async: true

  import Kozel.Table.Server
  import Kozel.Cards, only: [ available_turns: 2 ]

  defp receive_turn() do
    receive do
      {player, hand, table} ->
        {player, hand, table}
    after
      5000 ->
        assert false, "Timeout"
    end
  end

  setup do
    {:ok, pid} = :gen_server.start_link(Kozel.Table.Server, [], [])
    {:ok, pid: pid}
  end

  test "game", meta do
    server_pid = meta[:pid]

    {:ok, token1} = join(server_pid)
    {:ok, token2} = join(server_pid)
    {:ok, token3} = join(server_pid)
    {:ok, token4} = join(server_pid)

    hand1 = get_cards(server_pid, token1)
    hand2 = get_cards(server_pid, token2)
    hand3 = get_cards(server_pid, token3)
    hand4 = get_cards(server_pid, token4)

    assert Enum.count(hand1) == 8
    assert Enum.count(hand2) == 8
    assert Enum.count(hand3) == 8
    assert Enum.count(hand4) == 8

    self_pid = self

    players = [:player1, :player2, :player3, :player4]

    players_data = HashDict.new [{:player1, {token1, hand1}},
                                 {:player2, {token2, hand2}},
                                 {:player3, {token3, hand3}},
                                 {:player4, {token4, hand4}}]

    Process.spawn(fn() ->
                      {:you_turn, hand, table} = ready(server_pid, token1)
                      self_pid <- {:player1, hand, table}
                  end)
    Process.spawn(fn() ->
                      {:you_turn, hand, table} = ready(server_pid, token2)
                      self_pid <- {:player2, hand, table}
                  end)
    Process.spawn(fn() ->
                      {:you_turn, hand, table} = ready(server_pid, token3)
                      self_pid <- {:player3, hand, table}
                  end)
    Process.spawn(fn() ->
                      {:you_turn, hand, table} = ready(server_pid, token4)
                      self_pid <- {:player4, hand, table}
                  end)

    {player, hand, table} = receive_turn()

    assert Enum.member?(players, player) == true
    List.delete(players, player)

    {token, chand} = HashDict.fetch!(players_data, player)
    assert chand == hand
    assert Enum.count(hand) == 8
    assert Enum.count(table) == 0

    [card|_] = available_turns(hand, table)
    {:ok, {new_hand, new_table}} = :gen_server.call(server_pid, {:turn, token, card, hand})
    assert Enum.count(new_hand) == 7
    assert Enum.count(new_table) == 1

    players_data = HashDict.put(players_data, player, {token, new_hand})

    {player, hand, table} = receive_turn()

    assert Enum.member?(players, player) == true
    List.delete(players, player)

    {token, chand} = HashDict.fetch!(players_data, player)
    assert chand == hand
    assert Enum.count(hand) == 8
    assert Enum.count(table) == 1

    [card|_] = available_turns(hand, table)
    {:ok, {new_hand, new_table}} = :gen_server.call(server_pid, {:turn, token, card, hand})
    assert Enum.count(new_hand) == 7
    assert Enum.count(new_table) == 2
  end

end