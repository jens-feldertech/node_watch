defmodule NodeWatch.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      availability_checkers() ++
        [
          NodeWatchWeb.Telemetry,
          {Phoenix.PubSub, name: NodeWatch.PubSub},
          NodeWatchWeb.Endpoint,
          NodeWatch.SLA.Worker,
          NodeWatch.Integrity.Worker
        ]

    opts = [strategy: :one_for_one, name: NodeWatch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NodeWatchWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp availability_checkers do
    for node <- Application.get_env(:node_watch, :nodes) do
      Supervisor.child_spec({NodeWatch.AvailabilityWorker, node},
        id: "availability_checker_#{to_string(node.name)}"
      )
    end
  end
end
