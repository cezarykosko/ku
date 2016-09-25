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
  Publishes a message under a given key. Should key matches a subscriber's pattern,
  its callback function will be executed.

  Keys are strings containing any alphanumeric character (case sensitive), `.`, `-` and `_`.
  """
  def publish(key, body, metadata \\ ()) do
    GenStage.cast(Ku.Queue, {:publish, key, %{body: body, metadata: metadata}})
  end

  @doc """
  Given a pattern and a function, spawns a subscriber process.
  Returns pid if successful.

  Patterns are Graphite-like strings describing desired keys.
  Pattern that is a key (see `publish/3`) matches only that key.
  Furthermore, three additional behaviours are available:
  - `{a[1],a[2],a[3],...,a[n]}` matches any of
    `a[1]`,`a[2]`,...,`a[n]`, e.g. `ab{c,d,e}` matches `abc`, `abd`, `abe`;
  - `?` matches one character, e.g. `a?b` matches any key of length 3,
    whose first character is `a` and third is `b`;
  - `*` matches any number of characters, e.g. `ab*` matches keys starting with `ab`,
    while `ab{*d, ce}` matches strings starting with `ab` and ending with `d` and `abce`.

  Callbacks are `1`-arity functions.
  They will be passed (should relevant subscribers' patterns match some keys)
  maps with 2 keys: `body` and `metadata`.

  TODO: return ets ref
  """
  def subscribe(pattern, fun) do
    {:ok, subscriber} = Ku.SubSupervisor.subscribe(pattern, fun)
    GenStage.sync_subscribe(subscriber, to: Ku.Queue)
    subscriber
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
