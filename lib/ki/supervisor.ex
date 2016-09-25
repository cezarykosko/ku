defmodule Ki.Supervisor do
  use Supervisor

  @moduledoc """
  `Supervisor` responsible for handling the state of the whole application.
  """

  def start_link do
    {:ok, _sup} = Supervisor.start_link(__MODULE__, [])
  end

  @doc """
  Initializes the `Supervisor` behaviour.

  TODO: create an `ets` table for storing `Ki.SubSupervisor`'s state.
  """
  def init(_) do
    children =  [
      worker(Ki.Queue, []),
      supervisor(Ki.SubSupervisor, [])
    ]
    supervise children, strategy: :rest_for_one
  end

end
