alias Experimental.GenStage

defmodule Ki do
  def start do
    :application.ensure_all_started(:ki)
    Ki.Supervisor.start_link()
  end

  def subscribe(pattern, fun) do
    {:ok, subscriber} = Ki.SubSupervisor.subscribe(pattern, fun)
    GenStage.sync_subscribe(subscriber, to: Ki.Queue)
  end

  def publish(key, body, metadata) do
    GenStage.cast(Ki.Queue, {:publish, key, %{body: body, metadata: metadata}})
  end
end
