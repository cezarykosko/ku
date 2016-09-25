defmodule Ki.SubSupervisor do
  use Supervisor

  @moduledoc """
  `Supervisor` repsonsible for managing `Subscriber` processes.
  """

  def start_link do
    {:ok, _sup} = Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Spawns a new subscriber process.

  TODO: Add entry to an `ets` table.
  TODO: Return an `ets` `ref` for the process.
  """
  def subscribe(pattern, fun) do
    Supervisor.start_child(__MODULE__, [pattern, fun])
  end

  @doc """
  Sets the `Supervisor` behaviour up.

  TODO: Restore state from an `ets` table.
  """
  def init(_) do
    children = [
      worker(Ki.Subscriber, [])
    ]
    supervise children, strategy: :simple_one_for_one
  end
end
