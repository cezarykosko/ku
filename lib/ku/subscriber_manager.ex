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
      fn {ref, pattern, function}, acc ->
        Logger.info "Restarting Subscriber (ref: #{inspect(ref)})"
        _pid = spawn_subscriber(pattern, function, ref)
        [{ref, pattern, function} | acc]
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

  defp spawn_subscriber(compiled_pattern, function, ref) do
    {:ok, pid} = Ku.SubSupervisor.subscribe compiled_pattern, function, ref
    Logger.debug "Spawned subscriber: #{inspect(pid)}"
    pid
  end

  defp terminate_subscriber(ref) do
    Ku.SubSupervisor.unsubscribe ref
    Logger.debug "Terminated subscriber: #{inspect(pid)}"
  end

  def handle_call({:subscribe, pattern, function}, _from, table) do
    ref = make_ref()
    compiled_pattern = Ku.Subscriber.compile_pattern pattern
    Logger.info "Starting Subscriber for pattern: #{inspect(pattern)}"
    _pid = spawn_subscriber compiled_pattern, function, ref
    :ets.insert table, {ref, compiled_pattern, function}
    {:reply, {:ok, ref}, table}
  end
  def handle_call({:unsubscribe, ref}, _from, table) do
    terminate_subscriber ref
    :ets.delete table, ref
    {:reply, :ok, table}
  end
  def handle_call({:unsubscribe_all}, _from, table) do
    Ku.SubSupervisor.active_subscribers()
    |> Enum.map(&(elem(&1, 0)))
    |> Enum.each(&terminate_subscriber/1)

    :ets.delete_all_objects table
    {:reply, :ok, table}
  end
end
