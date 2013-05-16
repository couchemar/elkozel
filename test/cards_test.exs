Code.require_file "../test_helper.exs", __FILE__

defmodule Kozel.Cards.Test do
  import Kozel.Cards, only: [compare: 2]
  use ExUnit.Case

  test "compare cards" do
    assert compare({:spades, 10}, {:spades, 9}) == {{:spades, 10}, 0, 10}
    assert compare({:spades, 9}, {:spades, 10}) == {{:spades, 10}, 0, 10}
  end

  test "compare trumps" do
    assert compare({:spades, :q}, {:spades, :j}) == {{:spades, :q}, 13, 3}
    assert compare({:spades, :q}, {:clubs, :q}) == {{:clubs, :q}, 14, 3}
    assert compare({:spades, :j}, {:clubs, :j}) == {{:clubs, :j}, 10, 2}
  end

end