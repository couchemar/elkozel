defmodule Kozel.Table.Server do
  use GenServer.Behaviour

  import Kozel.Cards, only: [ produce_cards: 0,
                              deal: 1 ]

  def start_link() do
    :gen_server.start_link(__MODULE__, [], [])
  end

  defrecord TableState, round: :waiting, decs: []

  def init([]) do
    {h1, h2, h3, h4} = deal(produce_cards)
    {:ok, TableState.new(decs: [h1, h2, h3, h4])}
  end

  def handle_call(:get_cards, _from,
                  TableState[round: :waiting,
                             decs: decs]=state) when length(decs) > 0 do
    [d1|new_decs] = decs
    {:reply, d1, state.decs(new_decs)}
  end

  def handle_call(_msg, _from, state) do
    {:reply, {:error, "dont know what you mean"}, state}
  end

end