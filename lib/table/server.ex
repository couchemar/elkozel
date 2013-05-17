defmodule Kozel.Table.Server do
  use GenServer.Behaviour

  import Kozel.Cards, only: [ produce_cards: 0,
                              deal: 1 ]

  def start_link() do
    :gen_server.start_link(__MODULE__, [], [])
  end

  defrecord TableState, round: :waiting, decs: [], players: nil

  def init([]) do
    {h1, h2, h3, h4} = deal(produce_cards)
    {:ok, TableState.new(decs: [h1, h2, h3, h4])}
  end

  def handle_call(:get_cards, from,
                  TableState[round: :waiting,
                             decs: decs,
                             players: players]=state) when length(decs) > 0 do
    [d1|new_decs] = decs
    new_state = state.decs(new_decs)
    if players == nil do
      players = HashDict.new [{1, from}]
    else
      players = HashDict.put(players, HashDict.size(players) + 1, from)
    end
    new_state = new_state.players(players)
    {:reply, d1, new_state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, {:error, "dont know what you mean"}, state}
  end

end