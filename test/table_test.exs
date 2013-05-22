Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Table.Test.Client do
    import GenX.GenServer
    use GenServer.Behaviour

    alias Kozel.Table.Server, as: TS

    defrecord ClientState, table_pid: nil,
                           cast_receiver_pid: nil,
                           token: nil,
                           hand: []

    def start_link(table_pid, cast_receiver_pid) do
      :gen_server.start_link(__MODULE__, [table_pid, cast_receiver_pid], [])
    end

    def init([table_pid, cast_receiver_pid]) do
      {:ok, ClientState.new(table_pid: table_pid,
                            cast_receiver_pid: cast_receiver_pid)}
    end

    defcall join, state: ClientState[table_pid: table_pid]=state do
      token = TS.join(table_pid)
      {:reply, token, state.token(token)}
    end

    defcall get_cards, state: ClientState[table_pid: table_pid,
                                          token: token]=state do
      cards = TS.get_cards(table_pid, token)
      {:reply, cards, state.hand(cards)}
    end

    defcall ready, state: ClientState[table_pid: table_pid,
                                      token: token]=state do
      result = TS.ready(table_pid, token)
      case result do
        {:start_round, _round, hand, _table, _turns} ->
          state = state.hand(hand)
        _ ->
         :ok
      end
      {:reply, result, state}
    end

    defcall turn(card), state: ClientState[table_pid: table_pid,
                                           token: token,
                                           hand: hand]=state do
      {:reply, TS.turn(table_pid, token, card, hand), state}
    end

    def handle_cast({:next_turn, _round, hand, table, available_turns},
                    ClientState[cast_receiver_pid: receiver]=state) do
      state = state.hand(hand)
      receiver <- {self, hand, table, available_turns}
      {:noreply, state}
    end

    def handle_cast({:next_turn, _round, {:player, _next_move}, table},
                    ClientState[cast_receiver_pid: receiver]=state) do
      receiver <- {:new_table, table}
      {:noreply, state}
    end
end

defmodule Kozel.Table.Test do
  use ExUnit.Case, async: true

  alias Kozel.Table.Test.Client, as: TC

  defp receive_turn() do
    receive do
      {player, hand, table, turns} ->
        {player, hand, table, turns}
#      _ ->
#        receive_turn()
    after
      5000 ->
        flunk "Timeout"
    end
  end

  defp receive_new_table() do
    receive do
      {:new_table, table} ->
        table
#      _ ->
#        receive_new_table()
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

  setup do
    {:ok, table_pid} = :gen_server.start_link(Kozel.Table.Server, [], [])

    {:ok, pid1} = TC.start_link(table_pid, self)
    {:ok, pid2} = TC.start_link(table_pid, self)
    {:ok, pid3} = TC.start_link(table_pid, self)
    {:ok, pid4} = TC.start_link(table_pid, self)

    {:ok, pid1: pid1, pid2: pid2,
          pid3: pid3, pid4: pid4}
  end

  test "game", meta do
    pid1 = meta[:pid1]
    pid2 = meta[:pid2]
    pid3 = meta[:pid3]
    pid4 = meta[:pid4]

    token1  = TC.join(pid1)
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

    # round 1

    players = [pid1, pid2, pid3, pid4]

    Process.spawn(fn() -> spawn_ready(self_pid, pid1, 1) end)
    Process.spawn(fn() -> spawn_ready(self_pid, pid2, 1) end)
    Process.spawn(fn() -> spawn_ready(self_pid, pid3, 1) end)
    Process.spawn(fn() -> spawn_ready(self_pid, pid4, 1) end)

    {player, hand, table, available_turns} = receive_turn()
    assert_received {:new_table, table}
    assert_received {:new_table, table}
    assert_received {:new_table, table}

    assert Enum.member?(players, player) == true
    players = List.delete(players, player)

    assert Enum.count(hand) == 8
    assert Enum.count(table) == 0

    [card|_] = available_turns

    {new_hand, new_table} = TC.turn(player, card)
    assert Enum.count(new_hand) == 7
    assert Enum.count(new_table) == 1

    {player, hand, table, available_turns} = receive_turn()
    assert_received {:new_table, table}
    assert_received {:new_table, table}
    assert_received {:new_table, table}

    assert Enum.member?(players, player) == true
    players = List.delete(players, player)

    assert Enum.count(hand) == 8
    assert Enum.count(table) == 1

    [card|_] = available_turns

    {new_hand, new_table} = TC.turn(player, card)
    assert Enum.count(new_hand) == 7
    assert Enum.count(new_table) == 2

    {player, hand, table, available_turns} = receive_turn()
    assert_received {:new_table, table}
    assert_received {:new_table, table}
    assert_received {:new_table, table}

    assert Enum.member?(players, player) == true
    players = List.delete(players, player)

    assert Enum.count(hand) == 8
    assert Enum.count(table) == 2

    [card|_] = available_turns

    {new_hand, new_table} = TC.turn(player, card)
    assert Enum.count(new_hand) == 7
    assert Enum.count(new_table) == 3

    {player, hand, table, available_turns} = receive_turn()
    assert_received {:new_table, table}
    assert_received {:new_table, table}
    assert_received {:new_table, table}

    assert Enum.member?(players, player) == true
    players = List.delete(players, player)

    assert Enum.count(hand) == 8
    assert Enum.count(table) == 3

    [card|_] = available_turns

    {new_hand, new_table} = TC.turn(player, card)
    assert Enum.count(new_hand) == 7
    assert Enum.count(new_table) == 4

    

  end

end