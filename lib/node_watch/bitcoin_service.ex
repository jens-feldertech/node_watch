defmodule NodeWatch.BitcoinService do
  @moduledoc """
    This module is responsible for performing Bitcoin specific operations.
  """

  alias NodeWatch.RPCClient

  @max_blocks_behind Application.compile_env(:node_watch, :max_blocks_behind)

  def check_node_availability(node) do
    with {:ok, result} <- get_blockchain_info(node.url) do
      result
      |> get_availability_status(node.url)
      |> return_message(node)
    else
      error ->
        return_message(error, node)
    end
  end

  defp return_message(:synchronized, node) do
    {:ok, "availability_check; #{node.chain}; #{node.url}; Available - Fully synchronized"}
  end

  defp return_message({label, opts}, node) do
    base = "availability_check; #{node.chain}; #{node.url}; "

    case label do
      :synchronizing ->
        {:ok,
         base <>
           "Available - #{opts.blocks_behind}/#{@max_blocks_behind} blocks behind, #{opts.progress}% complete"}

      :behind_blocks ->
        {:error,
         base <>
           "Unavailable - #{opts.blocks_behind}/#{@max_blocks_behind} blocks behind, #{opts.progress}% complete"}

      :error ->
        {:error, base <> "Error connecting to node, status code #{opts.status_code}"}
    end
  end

  defp get_availability_status(result, url) do
    with {:ok, block_count} <- get_block_count(url) do
      blocks_behind = blocks_behind(result["blocks"], block_count)
      progress = result["verificationprogress"] * 100

      cond do
        progress == 100 ->
          :synchronized

        blocks_behind <= @max_blocks_behind ->
          {:synchronizing, %{blocks_behind: blocks_behind, progress: progress}}

        blocks_behind > @max_blocks_behind ->
          {:behind_blocks, %{blocks_behind: blocks_behind, progress: progress}}
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  defp blocks_behind(latest_block_number, block_count), do: block_count - latest_block_number

  defp get_block_count(url), do: RPCClient.post(:bitcoin, "getblockcount", url)

  defp get_blockchain_info(url), do: RPCClient.post(:bitcoin, "getblockchaininfo", url)
end
