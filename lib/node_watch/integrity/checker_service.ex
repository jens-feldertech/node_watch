defmodule NodeWatch.Integrity.CheckerService do
  @moduledoc """
    This module is responsible for performing integrity check for the node.
  """
  alias NodeWatch.RPCClient

  @config Application.compile_env(:node_watch, :integrity_check_methods)

  def check_node_integrity(node, cached_result) do
    methods = @config[node.chain]

    with {:ok, result} <- RPCClient.patch_post(node.chain, methods, node.url),
         true <- matching_result?(result, cached_result, node.chain) do
      {:ok, craft_message(node, "Integrity check passed")}
    else
      {:error, error} ->
        {:error, craft_message(node, "Failed to get result: #{inspect(error)}")}

      false ->
        {:error, craft_message(node, "Integrity check failed")}
    end
  end

  def get_initial_response(node) do
    methods = @config[node.chain]

    case RPCClient.patch_post(node.chain, methods, node.url) do
      {:ok, result} ->
        {:ok, result}

      {:error, error} ->
        {:error,
         "Failed to get initial result for #{node.chain} node #{node.url}: #{inspect(error)}"}
    end
  end

  defp matching_result?(result, cached_result, node_chain) do
    result == cached_result[node_chain]
  end

  defp craft_message(node, message), do: "integrity_check; #{node.chain}; #{node.url}; #{message}"
end
