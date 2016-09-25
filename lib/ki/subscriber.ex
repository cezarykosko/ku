alias Experimental.GenStage

defmodule Ki.Subscriber do
  use GenStage

  @moduledoc """
  Process responsible for digesting messages published to `Ki.Queue`
  and executing a given callback function if events' key matches given pattern.
  """

  @doc """
  Starts `Subscriber` as a `GenStage` process.
  """
  def start_link(pattern, fun) do
    GenStage.start_link(__MODULE__, {pattern, fun})
  end

  @doc """
  Compiles `pattern` to a regexp using a set of rules:
  - `.` is compiled to `\.`,
  - `*` is compiled to `(A-Za-z\d_\.)*`,
  - `?` is compiled to `(A-Za-z\d_\.)`,
  - any alphanumeric character is compiled to itself,
  - `_` is compiled to itself.

  TODO: implement
  """
  def compile_pattern(pattern), do: pattern

  @doc """
  Initializes `GenStage` behaviour, compiling given pattern.
  """
  def init({pattern, fun}) do
    {:consumer, {pattern, compile_pattern(fun)}}
  end

  @doc """
  Given a key and pattern, returns `true` if key matches the pattern,
  `false` otherwise.
  """
  def key_matches_pattern(key, pattern) do
    key === pattern
  end

  @doc """
  Handles events received as a GenStage process:
  for each event whose key matches the process' pattern,
  the process' function is executed, being given the event's message.
  """
  def handle_events([], _, s), do: {:noreply, [], s}
  def handle_events(events, _from, {pattern, fun}) do
    events
    |> Enum.filter(&(key_matches_pattern(&1.key, pattern)))
    |> Enum.each(&(fun.(&1.message)))

    {:noreply, [], {pattern, fun}}
  end
end
