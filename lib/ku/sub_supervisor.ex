defmodule Ku.SubSupervisor do
  use Supervisor
  require Logger

  @moduledoc """
  `Supervisor` repsonsible for managing `Subscriber` processes.
  """

  def start_link do
    {:ok, _sup} = Supervisor.start_link __MODULE__, [], name: __MODULE__
  end

  @doc """
  Spawns a new subscriber process.
  """
  def subscribe(pattern, fun, ref) do
    res = {:ok, pid} = Supervisor.start_child __MODULE__, worker(Ku.Subscriber, [pattern, fun], id: ref)
    Logger.debug "Created child: #{inspect(pid)}"
    res
  end

  @doc """
  Terminates a process given its `ref`.
  """
  def unsubscribe(ref) do
    Logger.debug "Terminating #{inspect(pid)}"
    Supervisor.terminate_child __MODULE__, ref
    Supervisor.delete_child __MODULE__, ref
  end

  @doc """
  Returns a list of `{ref, pid}` pairs of supervisor's current processes.
  """
  def active_subscribers do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {a,b,_,_} -> {a,b} end)
  end

  @doc """
  Sets the `Supervisor` behaviour up.
  """
  def init(_) do
    supervise [], strategy: :one_for_one
  end
end
