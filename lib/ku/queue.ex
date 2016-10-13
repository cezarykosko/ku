alias Experimental.GenStage

defmodule Ku.Queue do
  use GenStage
  require Logger

  @moduledoc """
  Process storing `Ku`'s event queue.
  """

  @doc """
  Starts `Queue` as a `GenStage` server.
  """
  def start_link do
    {:ok, _pid} = GenStage.start_link __MODULE__, :ok, name: __MODULE__
  end

  @doc """
  Initializes `GenStage`.
  """
  def init(:ok) do
    {:producer, {:queue.new, 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def attach(pid) do
    Logger.debug "Attaching #{inspect(pid)} to #{__MODULE__}"
    GenStage.sync_subscribe pid, to: __MODULE__
  end

  def detach(ref) do
    Logger.debug "Detaching #{inspect(ref)} from #{__MODULE__}"
    GenStage.cancel {__MODULE__, ref}, :normal
  end

  @doc """
  Casts given message to `Queue`'s instance.
  """
  def publish(key, message) do
    GenStage.cast __MODULE__, {:publish, key, message}
  end

  @doc """
  Handles `:publish` cast message, adding `%{key: key, message: msg}`.
  """
  def handle_cast({:publish, key, msg}, {queue, demand}) do
    Logger.debug "Received message: #{inspect(msg)} for key #{inspect(key)}."
    dispatch :queue.in(%{key: key, message: msg}, queue), demand
  end

  @doc """
  Handles `GenStage` demand.
  """
  def handle_demand(new_demand, {queue, demand}) do
    dispatch queue, new_demand + demand
  end

  defp dispatch(queue, demand, events \\ []) do
    with d when d > 0 <- demand,
         {item, queue} = :queue.out(queue),
         {:value, event} <- item do
      dispatch queue, demand - 1, [event | events]
    else
      _ ->
        Logger.debug "Dispatching #{length(events)} events."
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end
