defmodule Ki.SubSupervisor do
  use Supervisor

  def start_link do
    {:ok, _sup} = Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def subscribe(pattern, fun) do
    Supervisor.start_child(__MODULE__, [pattern, fun])
  end


  def init(_) do
    children = [
      worker(Ki.Subscriber, [])
    ]
    supervise children, strategy: :simple_one_for_one
  end
end
