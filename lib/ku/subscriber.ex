alias Experimental.GenStage

defmodule Ku.Subscriber do
  use GenStage
  require Logger

  @moduledoc """
  Process responsible for digesting messages published to `Ku.Queue`
  and executing a given callback function if events' key matches given pattern.
  """

  @doc """
  Starts `Subscriber` as a `GenStage` process.
  """
  def start_link(pattern, fun) do
    Logger.debug "Starting Subscriber for pattern: #{inspect(pattern)}"
    res = {:ok, pid} = GenStage.start_link __MODULE__, {pattern, fun}
    attach pid
    res
  end

  @doc """
  Compiles `pattern` to a regexp using a set of rules:
  - a comma-separated list surrounded by curly brackets is compiled
    to a pipe-separated list surrounded by parentheses (Regex alternative),
  - `.` is compiled to `\.`,
  - `*` is compiled to `[A-Za-z_\.\d]*`,
  - `?` is compiled to `[A-Za-z_\.\d]`,
  - any alphanumeric character is compiled to itself,
  - `_` and `-` are compiled to themselves.
  """
  def compile_pattern(pattern) do
    pat = pattern
    |> String.replace(".", "\\.")
    |> String.replace("*", "[A-Za-z_\\.\\d]*")
    |> String.replace("?", "[A-Za-z_\\.\\d]")
    |> String.replace("{", "(")
    |> String.replace("}", ")")
    |> String.replace(",", "|")

    {:ok, pat} = Regex.compile "^#{pat}$"
    pat
  end

  @doc """
  Initializes `GenStage` behaviour.
  """
  def init({pattern, fun}) do
    {:consumer, {pattern, fun, nil}}
  end

  defp attach(pid) do
    Logger.debug "Attaching #{inspect(pid) }to queue..."
    {:ok, sub_ref} = Ku.Queue.attach pid
    GenStage.cast pid, {:attach, sub_ref}
  end

  @doc """
  Handles cast with `GenStage` consumer ref, saving it in process' state.
  """
  def handle_cast({:attach, ref}, {pattern, fun, _}) do
    {:noreply, [], {pattern, fun, ref}}
  end

  @doc """
  Given a key and pattern, returns `true` if key matches the pattern,
  `false` otherwise.
  """
  def key_matches_pattern(key, pattern) do
    Regex.match? pattern, key
  end

  @doc """
  Handles events received as a GenStage process:
  for each event whose key matches the process' pattern,
  the process' function is executed, being given the event's message.
  """
  def handle_events([], _, s), do: {:noreply, [], s}
  def handle_events(events, _from, {pattern, fun, sub_ref}) do
    Logger.debug "Received #{length(events)} events."
    filtered_events = events
    |> Enum.filter(&(key_matches_pattern(&1.key, pattern)))

    Logger.debug "#{length(filtered_events)} matching key pattern"

    filtered_events
    |> Enum.each(&(fun.(&1.message)))

    {:noreply, [], {pattern, fun, sub_ref}}
  end

  @doc """
  On termination, detaches `GenStage` ref from `Ku.Queue`.
  """
  def terminate(reason, {_, _, sub_ref}) do
    Logger.info "Subscriber #{inspect(self)} terminating due to reason: #{inspect(reason)}"
    Ku.Queue.detach sub_ref
  end
end
