defmodule NodeWatch.Integrity.Worker do
  use GenServer

  alias NodeWatch.Integrity.Checker

  require Logger

  @module_enabled? Application.compile_env(:node_watch, :integrity_check_enabled)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    # Cache initial integrity_check response when the process starts
    cache = get_cache_state()

    {:ok, cache}
  end

  # TODO: refactor
  @impl true
  def handle_cast({:initiate_integrity_check, node}, cache) do
    # Check integrity only if node is trusted, perform_check? returns true and module is enabled
    if has_cached_response?(node, cache) and @module_enabled? and node.trusted and
         perform_check?() do
      node
      |> Checker.check_node_integrity(cache)
      |> log_message()

      {:noreply, cache}
    else
      if node.trusted do
        updated_cache_state = get_cache_state_for_node(node, cache)
        {:noreply, updated_cache_state}
      else
        {:noreply, cache}
      end
    end
  end

  defp get_cache_state() do
    trusted_nodes = get_trusted_nodes()

    Enum.reduce(trusted_nodes, %{}, fn node, acc ->
      get_cache_state_for_node(node, acc)
    end)
  end

  defp get_cache_state_for_node(node, cache) do
    case Checker.get_initial_response(node) do
      {:ok, response} ->
        Map.put(cache, node.name, response)

      {:error, message} ->
        log_message({:error, message})
        cache
    end
  end

  defp log_message({:ok, message}), do: Logger.info(message)
  defp log_message({:error, message}), do: Logger.error(message)

  # defp perform_check?(), do: Enum.random([true, false])
  # ! temporary
  defp perform_check?(), do: true

  defp get_trusted_nodes() do
    Application.get_env(:node_watch, :nodes)
    |> Enum.filter(& &1.trusted)
  end

  defp has_cached_response?(node, cache) do
    Map.has_key?(cache, node.name)
  end
end
