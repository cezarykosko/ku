defmodule Ku.SubscriberSupervisor do
  use Supervisor
  require Logger

  @moduledoc """
  Supervisor managing subscriber-related components.
  """

  def start_link(table) do
    {:ok, _sup} = Supervisor.start_link __MODULE__, table
  end

  @doc """
  Initializes the `Supervisor` behaviour.
  """
  def init(table) do
    children =  [
      supervisor(Ku.SubSupervisor, []),
      worker(Ku.SubscriberManager, [table]),
    ]
    supervise children, strategy: :one_for_all
  end
end
