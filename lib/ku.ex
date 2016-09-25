alias Experimental.GenStage

defmodule Ku do

  @moduledoc """
  Main module of the `Ku` pub/sub system.
  """

  @doc """
  Initializes Ku, by starting GenStage (if not yet started),
  as well as required supervisors/workers.
  """
  def start do
    :application.ensure_all_started(:ku)
    Ku.Supervisor.start_link()
  end

  @doc """
  Given a pattern (see `Ku.Subscriber.pattern_matches/1`)
  and a function, spawns a subscriber process.
  Returns pid if successful.

  TODO: return ets ref
  """
  def subscribe(pattern, fun) do
    {:ok, subscriber} = Ku.SubSupervisor.subscribe(pattern, fun)
    GenStage.sync_subscribe(subscriber, to: Ku.Queue)
    subscriber
  end

  @doc """
  Publishes a message under a given key.
  Should key matches a subscriber's pattern,
  its callback function will be executed, being passed
  a `%{body: body, metadata: metadata}` map.
  """
  def publish(key, body, metadata \\ ()) do
    GenStage.cast(Ku.Queue, {:publish, key, %{body: body, metadata: metadata}})
  end

  @doc """
  Removes all subscribers, effectively clearing Ku.

  TODO: Handle ets backup.
  """
  def clear do
    Supervisor.which_children(Ku.SubSupervisor)
    |> Enum.each(&(Supervisor.terminate_child(Ku.SubSupervisor, elem(&1, 1))))
  end
end
