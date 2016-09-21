defmodule Ki.Supervisor do
  use Supervisor

  def start_link do
    {:ok, _sup} = Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children =  [
      worker(Ki.Queue, []),
      supervisor(Ki.SubSupervisor, [])
    ]
    supervise children, strategy: :rest_for_one
  end

end
