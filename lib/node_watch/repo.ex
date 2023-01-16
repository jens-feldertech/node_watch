defmodule NodeWatch.Repo do
  use Ecto.Repo,
    otp_app: :node_watch,
    adapter: Ecto.Adapters.Postgres
end
