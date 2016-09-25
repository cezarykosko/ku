alias Experimental.GenStage

defmodule Ki do

  @moduledoc """
  Main module of the `Ki` pub/sub system.
  """

  @doc """
  Initializes Ki, by starting GenStage (if not yet started),
  as well as required supervisors/workers.
  """
  def start do
    :application.ensure_all_started(:ki)
    Ki.Supervisor.start_link()
  end

  @doc """
  Given a pattern (see `Ki.Subscriber.pattern_matches/1`)
  and a function, spawns a subscriber process.
  Returns pid if successful.

  TODO: return ets ref
  """
  def subscribe(pattern, fun) do
    {:ok, subscriber} = Ki.SubSupervisor.subscribe(pattern, fun)
    GenStage.sync_subscribe(subscriber, to: Ki.Queue)
    subscriber
  end

  @doc """
  Publishes a message under a given key.
  Should key matches a subscriber's pattern,
  its callback function will be executed, being passed
  a `%{body: body, metadata: metadata}` map.
  """
  def publish(key, body, metadata \\ ()) do
    GenStage.cast(Ki.Queue, {:publish, key, %{body: body, metadata: metadata}})
  end

  @doc """
  Removes all subscribers, effectively clearing Ki.

  TODO: Handle ets backup.
  """
  def clear do
    Supervisor.which_children(Ki.SubSupervisor)
    |> Enum.each(&(Supervisor.terminate_child(Ki.SubSupervisor, elem(&1, 1))))
  end
end
