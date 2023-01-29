defmodule NodeWatch.RPCClient do
  @moduledoc """
    This module is responsible for making RPC calls.
  """
  use HTTPoison.Base

  require Logger

  @config Application.compile_env(:node_watch, __MODULE__)
  @default_timeout 60_000
  @headers [{"Content-Type", "application/json"}]

  def post(chain, method, url) do
    body =
      Jason.encode!(%{
        jsonrpc: jsonrpc_version(chain),
        method: method,
        params: [],
        id: 1
      })

    post(url, body, @headers, timeout: timeout())
    |> format_response()
  end

  def patch_post(chain, methods, url) do
    body =
      methods
      |> enrich_methods(chain)
      |> Jason.encode!()

    post(url, body, @headers, timeout: timeout())
    |> format_patch_response()
  end

  defp format_patch_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    {:ok, Jason.decode!(body)}
  end

  defp format_patch_response({:ok, %HTTPoison.Response{status_code: status_code}}) do
    {:error, %{status_code: status_code}}
  end

  defp format_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    {:ok, Jason.decode!(body)["result"]}
  end

  defp format_response({:ok, %HTTPoison.Response{status_code: status_code}}) do
    {:error, %{status_code: status_code}}
  end

  # Returns timeout for HTTPoison
  # If timeout is not set in config, returns 60_000 by default
  # If timeout is set in config, but exceeds 60_000, returns 60_000 and logs warning
  defp timeout() do
    case @config[:http_timeout] do
      nil ->
        @default_timeout

      timeout ->
        if timeout > @default_timeout do
          Logger.warn("Timeout must not exceed 60 seconds")
          @default_timeout
        else
            timeout
        end
    end
  end

  # Returns JSON RPC version for given chain
  # If version is not set in config, returns "1.0" by default
  defp jsonrpc_version(chain) do
    case @config[:jsonrpc_version][chain] do
      nil -> "1.0"
      version -> version
    end
  end

  # Enriches methods with JSON RPC version and ID
  defp enrich_methods(methods, chain) do
    Enum.with_index(methods, fn method, i ->
      method
      |> Map.put(:jsonrpc, jsonrpc_version(chain))
      |> Map.put(:id, i + 1)
    end)
  end
end
