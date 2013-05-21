defmodule Kozel.Cards do

  @type suit :: :clubs | :spades | :hearts | :diamonds
  @type value :: 7..10 | :j | :q | :k | :a
  @type card :: {suit, value}

  @type card_cost :: 0 | 2..4 | 10 | 11
  @type card_power :: 0..14

  @suits [ :clubs, :spades, :hearts, :diamonds ]
  @names [:a, :k, :q, :j, 10, 9, 8, 7 ]

  @suit_symbols [ clubs: "♣",
                  spades: "♠",
                  hearts: "♥",
                  diamonds: "♦" ]

  @cards_cost [ {:a, 11},
                {:k, 4},
                {:q, 3},
                {:j, 2},
                {10, 10},
                {9, 0},
                {8, 0},
                {7, 0} ]

  @trumps_power [
                 {{:clubs, :q}, 14},
                 {{:spades, :q}, 13},
                 {{:hearts, :q}, 12},
                 {{:diamonds, :q}, 11},

                 {{:clubs, :j}, 10},
                 {{:spades, :j}, 9},
                 {{:hearts, :j}, 8},
                 {{:diamonds, :j}, 7},

                 {{:diamonds, :a}, 6},
                 {{:diamonds, 10}, 5},
                 {{:diamonds, :k}, 4},
                 {{:diamonds, 9}, 3},
                 {{:diamonds, 8}, 2},
                 {{:diamonds, 7}, 1}
                ]

  @spec get_power(card) :: card_power
  defp get_power(card) do
    {_, power} = List.keyfind(@trumps_power, card, 0, {0, 0})
    power
  end

  @spec get_cost(card) :: card_cost
  defp get_cost({_suite, card_name}) do
    {_, cost} = List.keyfind(@cards_cost, card_name, 0, {0, 0})
    cost
  end

  @spec compare(card, card) :: {card, card_power, card_cost}
  def compare(card1, card2) do
    p1 = get_power(card1)
    p2 = get_power(card2)

    {card, power} = if p1 >= p2 do
                      {card1, p1}
                    else
                      {card2, p2}
                    end
    if power == 0 do
      c1 = get_cost(card1)
      c2 = get_cost(card2)
      if c1 > c2 do
        {card1, 0, c1}
      else
        {card2, 0, c2}
      end
    else
      {card, power, get_cost(card)}
    end
  end

  defp shuffle(pool) do
    shuffled_pool = Enum.sort lc c inlist pool, do: {:random.uniform, c}
    lc {_, c} inlist shuffled_pool, do: c
  end

  def deal(pool) do
    hands_count = 4
    poll_len = Enum.count(pool)
    if rem(poll_len, hands_count) != 0 do
      raise "Could not split #{pool} to 4 parts"
    end

    shuffled_pool = shuffle(pool)
    deck_len = div(poll_len, hands_count)
    {hand1, rest} = Enum.split shuffled_pool, deck_len
    {hand2, rest} = Enum.split rest, deck_len
    {hand3, hand4} = Enum.split rest, deck_len
    {hand1, hand2, hand3, hand4}
  end

  def produce_cards() do
    lc s inlist @suits, n inlist @names, do: {s, n}
  end

  def check_hand(card, hand) do
    if Enum.member?(hand, card) do
      :ok
    else
      {:error, "Move with not exists card"}
    end
  end

  defp split_cards(hand) do
    Enum.partition hand, fn(card) -> get_power(card) == 0 end
  end

  def available_turns(hand, []) do
    { cards, trumps } = split_cards(hand)
    if Enum.empty? cards do
      trumps
    else
      cards
    end
  end
  def available_turns(hand, table) do
    { cards, trumps } = split_cards(hand)
    {_, start_card} = List.last(table)
    if get_power(start_card) > 0 do
      trumps
    else
      {suit, _} = start_card
      suit_cards = Enum.filter cards, fn({s, _}) -> s == suit end
      if Enum.empty? suit_cards do
        hand
      else
        suit_cards
      end
    end
  end

  def process_turn(card, hand, player, table) do
    hand2 = List.delete hand, card
    table2 = [ { player, card } | table]
    {hand2, table2}
  end

  defp count_cards(table) do
    Enum.reduce table, 0, fn({_pid, c}, acc) -> get_cost(c) + acc end
  end

  defp compare_turns({_pid1, c1} = t1, {_pid2, c2} = t2) do
    case compare(c1, c2) do
      {^c1, _, _} ->
        t1
      {^c2, _, _} ->
        t2
    end
  end

  defp max_trump(table) do
    Enum.reduce table, Enum.fetch!(table, 0), fn(c, acc) -> compare_turns(c, acc) end
  end

  def max_card(table) do
    {_, {suit, _}} = List.last(table)
    Enum.reduce(table,
                Enum.fetch!(table, 0),
                fn({_, {s, _}}=c, acc) ->
                    if s == suit do
                      compare_turns(c, acc)
                    else
                      acc
                    end
                end)
  end

  def count(table) do
    {_, trumps} = Enum.partition table, fn({_pid, card}) -> get_power(card) == 0 end

    {leader, _} = if !Enum.empty? trumps do
                    max_trump(trumps)
                  else
                    max_card(table)
                  end
    {leader, count_cards(table)}
  end


end