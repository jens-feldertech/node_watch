defmodule NodeWatch.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do

    children = [
      NodeWatchWeb.Telemetry,
      {Phoenix.PubSub, name: NodeWatch.PubSub},
      NodeWatchWeb.Endpoint,
      NodeWatch.SLA.Worker,
      NodeWatch.Integrity.Worker
    ]
    ++ availability_checkers()

    opts = [strategy: :one_for_one, name: NodeWatch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Define availability checkers for each node in the config
  defp availability_checkers do
    for node <- Application.get_env(:node_watch, :nodes) do
      Supervisor.child_spec({NodeWatch.AvailabilityWorker, node},
        id: "availability_checker_#{to_string(node.name)}"
      )
    end
  end

  @impl true
  def config_change(changed, _new, removed) do
    NodeWatchWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
