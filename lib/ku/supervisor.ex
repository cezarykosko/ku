defmodule Ku.Supervisor do
  use Supervisor
  require Logger

  @moduledoc """
  `Supervisor` responsible for handling the state of the whole application.
  """

  @procs_table :ku_subscribers

  def start_link do
    :ets.new(@procs_table,
      [:named_table,
       :public,
       read_concurrency: false,
       write_concurrency: false,
      ])
    res = {:ok, _sup} = Supervisor.start_link __MODULE__, []
    Logger.info "Ku supervisor started."
    res
  end

  @doc """
  Initializes the `Supervisor` behaviour.
  """
  def init(_) do
    children =  [
      worker(Ku.Queue, []),
      supervisor(Ku.SubSupervisor, []),
      worker(Ku.SubscriberManager, [@procs_table]),
    ]
    supervise children, strategy: :rest_for_one
  end

end
