defmodule NodeWatch.RPCClient do
  @moduledoc """
  Client for making requests to JASON RPC.
  """
  use HTTPoison.Base

  require Logger

  @config Application.compile_env(:node_watch, __MODULE__)

  def post(chain, method, url) do
    headers = [{"Content-Type", "application/json"}]

    body =
      Jason.encode!(%{
        jsonrpc: jsonrpc_version(chain),
        method: method,
        params: [],
        id: 1
      })

    post(url, body, headers, timeout: timeout())
    |> format_response()
  end

  def patch_post(chain, methods, url) do
    body = methods
    |> enrich_methods(chain)
    |> Jason.encode!()

    headers = [{"Content-Type", "application/json"}]

    post(url, body, headers, timeout: timeout())
    |> format_patch_response()
  end

  # TODO: change
  defp format_patch_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    {:ok, Jason.decode!(body)}
  end

  # TODO: change
  defp format_patch_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}}) do
    {:error, %{status_code: status_code, body: Jason.decode!(body)}}
  end

  defp format_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    {:ok, Jason.decode!(body)["result"]}
  end

  defp format_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}}) do
    {:error, %{status_code: status_code, body: Jason.decode!(body)}}
  end

  defp timeout() do
    case @config[:http_timeout] do
      nil ->
        60_000

      timeout ->
        case timeout > 60_000 do
          true ->
            raise "Timeout must not exceed 60 seconds"
            60_000

          false ->
            timeout
        end
    end
  end

  defp jsonrpc_version(chain) do
    case @config[:jsonrpc_version][chain] do
      nil -> "1.0"
      version -> version
    end
  end

  defp enrich_methods(methods, chain) do
    Enum.with_index(methods, fn method, i ->
      method
      |> Map.put(:jsonrpc, jsonrpc_version(chain))
      |> Map.put(:id, i+1)
    end)
  end
end
