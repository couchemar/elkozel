defmodule Kozel.Table.Server do
  use GenServer.Behaviour

  import Kozel.Cards, only: [ produce_cards: 0,
                              deal: 1 ]

  def start_link() do
    :gen_server.start_link(__MODULE__, [], [])
  end

  defrecord TableState, round: :waiting_joins,
                        decs: [],
                        players_by_id: nil,
                        ids_by_token: nil,
                        hands_by_token: nil,
                        next_move: 0

  def init([]) do
    {h1, h2, h3, h4} = deal(produce_cards)
    {:ok, TableState.new(decs: [h1, h2, h3, h4])}
  end

  def handle_call(:join, from,
                  TableState[round: :waiting_joins,
                             decs: decs,
                             players_by_id: players,
                             ids_by_token: ids]=state) do
    token = :os.timestamp
    if players == nil do
      id = 1
      players = HashDict.new [{id, from}]
    else
      id = HashDict.size(players) + 1
      players = HashDict.put players, id, from
    end

    if ids == nil do
      tokens = HashDict.new [{token, id}]
    else
      tokens = HashDict.put ids, token, id
    end

    new_state = state.players_by_id(players)
    {:reply, {:ok, token}, new_state.ids_by_token(tokens)}
  end

  def handle_call({:get_cards, token}, _from,
                  TableState[decs: decs,
                            hands_by_token: hands]=state) when length(decs) > 0 do
    [d|new_decs] = decs
    if hands == nil do
      hands = HashDict.new [{token, d}]
    else
      hands = HashDict.put hands, token, d
    end
    new_state = state.decs(new_decs)
    {:reply, d, new_state.hands_by_token(hands)}
  end

  def handle_call(_msg, _from, state) do
    IO.inspect(state)
    {:reply, {:error, "dont know what you mean"}, state}
  end

end