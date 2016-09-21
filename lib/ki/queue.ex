alias Experimental.GenStage

defmodule Ki.Queue do
  use GenStage
  require Logger

  def start_link do
    {:ok, _pid} = GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:producer, {:queue.new, 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_cast({:publish, key, msg}, {queue, demand}) do
    dispatch(:queue.in(%{key: key, message: msg}, queue), demand)
  end

  def handle_demand(new_demand, {queue, demand}) do
    dispatch(queue, new_demand + demand)
  end

  defp dispatch(queue, demand, events \\ []) do
    with d when d > 0 <- demand,
         {item, queue} = :queue.out(queue),
         {:value, event} <- item do
      dispatch(queue, demand - 1, [event | events])
    else
      _ -> {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end
