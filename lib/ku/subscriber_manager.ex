defmodule Ku.SubscriberManager do
  use GenServer
  require Logger

  @moduledoc """
  Process responsible for spawning/terminating subscribers
  """

  def start_link(table) do
    {:ok, _pid} = GenServer.start_link __MODULE__, table, name: __MODULE__
  end

  def init(table) do
    restarted = :ets.foldl(
      fn {ref, pid, pattern, function}, acc ->
        Logger.info "Restarting Subscriber (ref: #{inspect(ref)})"
        pid = spawn_subscriber(pattern, function)
        [{ref, pid, pattern, function} | acc]
      end,
      [],
      table)
    Logger.debug "Restarted #{length(restarted)} subscribers:\n#{inspect(restarted)}"
    :ets.insert table, restarted
    {:ok, table}
  end

  def subscribe(pattern, function) do
    GenServer.call __MODULE__, {:subscribe, pattern, function}
  end

  def unsubscribe(ref) do
    GenServer.call __MODULE__, {:unsubscribe, ref}
  end

  def unsubscribe_all do
    GenServer.call __MODULE__, {:unsubscribe_all}
  end

  defp spawn_subscriber(compiled_pattern, function) do
    {:ok, pid} = Ku.SubSupervisor.subscribe compiled_pattern, function
    Logger.debug "Spawned subscriber: #{inspect(pid)}"
    pid
  end

  defp terminate_subscriber(pid) do
    Ku.SubSupervisor.unsubscribe pid
    Logger.debug "Terminated subscriber: #{inspect(pid)}"
  end

  def handle_call({:subscribe, pattern, function}, _from, table) do
    ref = make_ref()
    compiled_pattern = Ku.Subscriber.compile_pattern pattern
    Logger.info "Starting Subscriber for pattern: #{inspect(pattern)}"
    pid = spawn_subscriber compiled_pattern, function
    :ets.insert table, {ref, pid, compiled_pattern, function}
    {:reply, {:ok, ref}, table}
  end
  def handle_call({:unsubscribe, ref}, _from, table) do
    [{^ref, pid, _pattern, _function}] = :ets.lookup table, ref
    terminate_subscriber pid
    :ets.delete table, ref
    {:reply, :ok, table}
  end
  def handle_call({:unsubscribe_all}, _from, table) do
    Ku.SubSupervisor.active_subscribers()
    |> Enum.each(&terminate_subscriber/1)

    :ets.delete_all_objects table
    {:reply, :ok, table}
  end
end
