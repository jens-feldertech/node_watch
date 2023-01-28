defmodule NodeWatch.AvailabilityWorker do
  use GenServer

  alias NodeWatch.Bitcoin
  alias NodeWatch.Ethereum
  # alias NodeWatch.Integrity.Checker

  require Logger

  @initial_interval Application.compile_env(:node_watch, :initial_check_interval)

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    schedule_next_check()
    {:ok, state}
  end

  @impl true
  def handle_info(:check_availability, node) do
    check_availability(node)

    # Check integrity only if node is trusted and perform_check? returns true
    maybe_check_integrity(node)

    schedule_next_check()
    {:noreply, node}
  end

  defp maybe_check_integrity(node) do
    GenServer.cast(NodeWatch.Integrity.Worker, {:initiate_integrity_check, node})
  end

  defp schedule_next_check do
    Process.send_after(self(), :check_availability, schedule_interval())
  end

  # Randomly generates the next interval in milliseconds
  # with the granularity of 1 second.
  defp schedule_interval do
    1..@initial_interval
    |> Enum.random()
    |> Kernel.*(1000)
  end

  defp check_availability(node) do
    node
    |> check_node_availability()
    |> log_message()
  end

  defp check_node_availability(%{chain: :ethereum} = node),
    do: Ethereum.check_node_availability(node)

  defp check_node_availability(%{chain: :bitcoin} = node),
    do: Bitcoin.check_node_availability(node)

  defp log_message({:ok, message}), do: Logger.info(message)
  defp log_message({:error, message}), do: Logger.error(message)
end
