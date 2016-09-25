alias Experimental.GenStage

defmodule Ki.Queue do
  use GenStage

  @moduledoc """
  Process storing `Ki`'s event queue.
  """

  require Logger

  @doc """
  Starts `Queue` as a `GenStage` server.
  """
  def start_link do
    {:ok, _pid} = GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Initializes `GenStage`.
  """
  def init(:ok) do
    {:producer, {:queue.new, 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  @doc """
  Handles `:publish` cast message, adding `%{key: key, message: msg}`.
  """
  def handle_cast({:publish, key, msg}, {queue, demand}) do
    dispatch(:queue.in(%{key: key, message: msg}, queue), demand)
  end

  @doc """
  Handles `GenStage` demand.
  """
  def handle_demand(new_demand, {queue, demand}) do
    dispatch(queue, new_demand + demand)
  end

  @doc """
  Dispatches at most `demand` messages from `queue`, adding them
  on top of `events`
  """
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
