alias Experimental.GenStage

defmodule Ki.Subscriber do
  use GenStage

  def start_link(pattern, fun) do
    GenStage.start_link(__MODULE__, {pattern, fun})
  end

  def init({pattern, fun}) do
    {:consumer, {pattern, fun}}
  end

  def handle_events([], _, s), do: {:noreply, [], s}
  def handle_events(events, _from, {pattern, fun}) do
    events
    |> Enum.filter(&(&1.key === pattern))
    |> Enum.each(&(fun.(&1.message)))

    {:noreply, [], {pattern, fun}}
  end
end
