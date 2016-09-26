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
  def subscribe(pattern, fun) do
    res = {:ok, pid} = Supervisor.start_child __MODULE__, [pattern, fun]
    Logger.debug "Created child: #{inspect(pid)}"
    res
  end

  @doc """
  Terminates a process given its `pid`.
  """
  def unsubscribe(pid) do
    Logger.debug "Terminating #{inspect(pid)}"
    Supervisor.terminate_child __MODULE__, pid
  end

  @doc """
  Returns a list of `pid`s of supervisor's current processes.
  """
  def active_subscribers do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(&(elem(&1, 1)))
  end

  @doc """
  Sets the `Supervisor` behaviour up.
  """
  def init(_) do
    children = [
      worker(Ku.Subscriber, [])
    ]
    supervise children, strategy: :simple_one_for_one
  end
end
