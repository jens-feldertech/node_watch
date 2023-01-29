defmodule NodeWatch.Integrity.Worker do
  @moduledoc """
    This module is responsible for initiating integrity check for a node provided by the caller.
    It will cache the initial response from trusted nodes
    and compare it with the response from the node provided by the caller when the integrity check is initiated.
  """

  use GenServer

  alias NodeWatch.Integrity.CheckerService

  require Logger

  @module_enabled? Application.compile_env(:node_watch, :integrity_check_enabled)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    # Cache initial integrity_check response from trusted nodes when the process starts
    cache = get_cache_state()

    {:ok, cache}
  end

  @impl true
  def handle_cast({:initiate_integrity_check, node}, cache) do
    # Check integrity only if node is trusted, do_perform_check? returns true and module is enabled in config
    if @module_enabled? and
         chain_has_chached_response?(node.chain, cache) and
         do_perform_check?() and
         not node.trusted do
      node
      |> CheckerService.check_node_integrity(cache)
      |> log_message()
    end

    {:noreply, cache}
  end

  defp get_cache_state() do
    trusted_nodes = get_trusted_nodes()

    Enum.reduce(trusted_nodes, %{}, fn node, acc ->
      get_cache_state_for_node(node, acc)
    end)
  end

  defp get_cache_state_for_node(node, cache) do
    case CheckerService.get_initial_response(node) do
      {:ok, response} ->
        Map.put(cache, node.chain, response)

      {:error, message} ->
        log_message({:error, message})
        cache
    end
  end

  defp log_message({:ok, message}), do: Logger.info(message)
  defp log_message({:error, message}), do: Logger.error(message)

  defp do_perform_check?(), do: Enum.random([true, false])

  defp get_trusted_nodes() do
    Application.get_env(:node_watch, :nodes)
    |> Enum.filter(& &1.trusted)
  end

  defp chain_has_chached_response?(chain, cache), do: Map.has_key?(cache, chain)
end
