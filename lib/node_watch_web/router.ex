defmodule NodeWatchWeb.Router do
  use NodeWatchWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {NodeWatchWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", NodeWatchWeb do
    pipe_through :browser

    live "/", Dashboard
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:node_watch, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: NodeWatchWeb.Telemetry
    end
  end
end
