defmodule NodeWatch.AvailabilityWorker do
  use GenServer

  alias NodeWatch.Bitcoin
  alias NodeWatch.Ethereum
  alias NodeWatch.IntegrityChecker

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
  def handle_info(:check_availability, state) do
    check_availability(state.node)

    # Check integrity only if node is trusted and perform_check? returns true
    if perform_check?() and state.node.trusted do
      check_integrity(state.node, state.cache)
    end

    schedule_next_check()
    {:noreply, state}
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

  defp check_node_availability(%{chain: :ethereum} = node), do: Ethereum.check_node_availability(node)
  defp check_node_availability(%{chain: :bitcoin} = node), do: Bitcoin.check_node_availability(node)

  # Cache initial result if cache is empty
  defp check_integrity(node, nil) do
    case IntegrityChecker.get_initial_result(node) do
      {:ok, result} ->
        fill_cache(result)

      {:error, message} -> log_message({:error, message})
    end
  end

  defp check_integrity(node, cache) do
    node
    |> IntegrityChecker.check_node_integrity(cache)
    |> log_message()
  end

  defp log_message({:ok, message}), do: Logger.info(message)
  defp log_message({:error, message}), do: Logger.error(message)

  defp fill_cache(response), do: GenServer.cast(self(), {:put, :cache, response})

  defp perform_check?(), do: Enum.random([true, false])

  @impl true
  def handle_cast({:put, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end

  @impl true
  def handle_cast({:get, key}, state) do
    {:reply, Map.get(state, key)}
  end
end
