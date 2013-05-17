Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Cards.Test do
  import Kozel.Cards, only: [ compare: 2,
                              deal: 1,
                              produce_cards: 0,
                              check_hand: 2,
                              available_turns: 2,
                              turn: 4 ]
  use ExUnit.Case, async: true

  test "compare cards" do
    assert compare({:spades, 10}, {:spades, 9}) == {{:spades, 10}, 0, 10}
    assert compare({:spades, 9}, {:spades, 10}) == {{:spades, 10}, 0, 10}
  end

  test "compare trumps" do
    assert compare({:spades, :q}, {:spades, :j}) == {{:spades, :q}, 13, 3}
    assert compare({:spades, :q}, {:clubs, :q}) == {{:clubs, :q}, 14, 3}
    assert compare({:spades, :j}, {:clubs, :j}) == {{:clubs, :j}, 10, 2}
  end

  test "deal" do
    pool = produce_cards()
    {hand1, hand2, hand3, hand4} = deal(pool)
    assert Enum.count(hand1) == 8
    assert Enum.count(hand2) == 8
    assert Enum.count(hand3) == 8
    assert Enum.count(hand4) == 8

    assert Enum.sort(List.flatten([hand1, hand2, hand3, hand4])) == Enum.sort(pool)
  end

  test "check card existance" do
    assert check_hand({:spades, :q}, []) == {:error, "Move with not exists card"}
    assert check_hand({:spades, :q}, [{:spades, :j}]) == {:error, "Move with not exists card"}

    assert check_hand({:spades, :q}, [{:spades, :q}]) == :ok
  end

  test "available turns" do
    # Empty table
    assert available_turns([{:spades, 8},
                            {:diamonds, 7},
                            {:clubs, :j},
                            {:hearts, :a}], []) == [{:spades, 8},
                                                    {:hearts, :a}]
    assert available_turns([{:diamonds, 7},
                            {:clubs, :j},
                            {:hearts, :q}], []) == [{:diamonds, 7},
                                                    {:clubs, :j},
                                                    {:hearts, :q}]

    # With table
    assert available_turns([{:spades, 8},
                            {:diamonds, 7},
                            {:clubs, :j},
                            {:hearts, :a}], [{0, {:spades, :a}}]) == [{:spades, 8}]
    assert available_turns([{:diamonds, 7},
                            {:clubs, :j},
                            {:hearts, :a}], [{0, {:spades, :a}}]) == [{:diamonds, 7},
                                                                      {:clubs, :j},
                                                                      {:hearts, :a}]
    assert available_turns([{:diamonds, 7},
                            {:clubs, :j},
                            {:hearts, :a}], [{0, {:spades, :q}}]) == [{:diamonds, 7},
                                                                      {:clubs, :j}]
  end

  test "turn" do
    assert turn({:spades, :q},
                [{:spades, :q}, {:spades, :j}],
                0, []) == {[{:spades, :j}], [{0, {:spades, :q}}]}

  end

end