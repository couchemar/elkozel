Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Cards.Test do
  import Kozel.Cards, only: [compare: 2,
                             deal: 1,
                             produce_cards: 0]
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

end