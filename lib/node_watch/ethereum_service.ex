defmodule NodeWatch.EthereumService do
  @moduledoc """
    This module is responsible for performing Ethereum specific operations.
  """
  alias NodeWatch.RPCClient

  @max_blocks_behind Application.compile_env(:node_watch, :max_blocks_behind)

  def check_node_availability(node) do
    case get_syncing_status(node.url) do
      {:ok, false} ->
        return_message(:fully_synchronized, node)

      {:ok, result} ->
        result
        |> get_availability_status(node.url)
        |> return_message(node)

      error ->
        return_message(error, node)
    end
  end

  defp get_availability_status(result, url) do
    with {:ok, latest_block_number} <- get_latest_block_number(url) do
      blocks_behind = blocks_behind(result["highestBlock"], latest_block_number)

      if blocks_behind <= @max_blocks_behind do
        {:within_max_blocks_behind, blocks_behind}
      else
        {:exceeds_max_blocks_behind, blocks_behind}
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  defp blocks_behind(highest_block_number, latest_block_number) do
    hex_to_integer(latest_block_number) - hex_to_integer(highest_block_number)
  end

  defp return_message(:fully_synchronized, node) do
    {:ok, "availability_check; #{node.chain}; #{node.url}; Available - Fully synchronized"}
  end

  defp return_message({label, opts}, node) do
    base = "availability_check; #{node.chain}; #{node.url}; "

    case label do
      :within_max_blocks_behind ->
        {:ok, base <> "Available - #{opts.blocks_behind}/#{@max_blocks_behind} blocks behind"}

      :exceeds_max_blocks_behind ->
        {:error,
         base <> "Unavailable - #{opts.blocks_behind}/#{@max_blocks_behind} blocks behind"}

      :error ->
        {:error, base <> "Error connecting to node, status code #{opts.status_code}"}
    end
  end

  defp get_syncing_status(url), do: RPCClient.post(:ethereum, "eth_syncing", url)

  defp get_latest_block_number(url), do: RPCClient.post(:ethereum, "eth_blockNumber", url)

  defp hex_to_integer(<<"0x", block_number::binary>>),
    do: :erlang.binary_to_integer(block_number, 16)
end
