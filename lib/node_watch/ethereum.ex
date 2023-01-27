defmodule NodeWatch.Ethereum do
  alias NodeWatch.RPCClient

  @max_blocks_behind Application.compile_env(:node_watch, :max_blocks_behind)

  def check_node_availability(node) do
    case get_syncing_status(node.url) do
      {:ok, false} ->
        {:ok, craft_message(node, "Available - Fully synchronized")}

      {:ok, result} ->
        case availability_status(result, node.url) do
          {:within_max_blocks_behind, blocks_behind} ->
            {:ok, craft_message(node, "Available - #{blocks_behind}/#{@max_blocks_behind} blocks behind")}

          {:exceeds_max_blocks_behind, blocks_behind} ->
            {:error, craft_message(node, "Unavailable - #{blocks_behind}/#{@max_blocks_behind} blocks behind")}
        end

      {:error, _error} ->
        {:error, craft_message(node, "Error connecting to ethereum node")}
    end
  end

  defp availability_status(result, url) do
    # TODOL handle error
    {:ok, latest_block_number} = get_latest_block_number(url)

    blocks_behind = blocks_behind(result["highestBlock"], latest_block_number)

    if blocks_behind <= @max_blocks_behind do
      {:within_max_blocks_behind, blocks_behind}
    else
      {:exceeds_max_blocks_behind, blocks_behind}
    end
  end

  defp blocks_behind(highest_block_number, latest_block_number) do
    hex_to_integer(latest_block_number) - hex_to_integer(highest_block_number)
  end

  defp get_syncing_status(url), do: RPCClient.post(:ethereum, "eth_syncing", url)

  defp get_latest_block_number(url), do: RPCClient.post(:ethereum, "eth_blockNumber", url)

  defp hex_to_integer(<<"0x", block_number::binary>>),
    do: :erlang.binary_to_integer(block_number, 16)

  defp craft_message(node, message), do: "availability_check; #{node.chain}; #{node.url}; #{message}"
end
