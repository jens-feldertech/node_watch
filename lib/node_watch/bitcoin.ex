defmodule NodeWatch.Bitcoin do
  @moduledoc """
  Bitcoin module for checking node availability
  """

  alias NodeWatch.RPCClient

  @max_blocks_behind Application.compile_env(:node_watch, :max_blocks_behind)

  def check_node_availability(node) do
    with {:ok, result} <- get_blockchain_info(node.url) do
      case availability_status(result, node.url) do
        :synchronized ->
          {:ok, craft_message(node, "Available - Fully synchronized")}

        {:synchronizing, blocks_behind, progress} ->
          {:ok, craft_message(node, "Available - #{blocks_behind}/#{@max_blocks_behind} blocks behind, #{progress}% complete")}

        {:behind_blocks, blocks_behind, progress} ->
          {:error, craft_message(node, "Unavailable - #{blocks_behind}/#{@max_blocks_behind} blocks behind, #{progress}% complete")}
      end
    else
      {:error, _error} ->
        {:error, craft_message(node, "Error connecting to bitcoin node")}
    end
  end

  defp availability_status(result, url) do
    blocks_behind = blocks_behind(result["blocks"], url)
    progress = result["verificationprogress"]*100

    cond do
      progress == 100 -> :synchronized
      blocks_behind <= @max_blocks_behind -> {:synchronizing, blocks_behind, progress}
      blocks_behind > @max_blocks_behind -> {:behind_blocks, blocks_behind, progress}
    end
  end

  defp blocks_behind(latest_block_number, url) do
    # TODO: handle error
    {:ok, block_count} = get_block_count(url)
    block_count - latest_block_number
  end

  defp get_block_count(url), do: RPCClient.post(:bitcoin, "getblockcount", url)

  defp get_blockchain_info(url), do: RPCClient.post(:bitcoin, "getblockchaininfo", url)

  defp craft_message(node, message), do: "availability_check; #{node.chain}; #{node.url}; #{message}"
end
