# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :node_watch,
  ecto_repos: [NodeWatch.Repo]

# Configures the endpoint
config :node_watch, NodeWatchWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: NodeWatchWeb.ErrorHTML, json: NodeWatchWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: NodeWatch.PubSub,
  live_view: [signing_salt: "1oL41nh5"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.1.8",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger,
  backends: [:console, {LoggerFileBackend, :info}],
  level: :debug

config :logger, :info,
  path: "logs/availability.log",
  format: "$date; $time; [$level]; $message \n",
  level: :info

config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# Main configs
config :node_watch, :nodes, [
  %{
    url: "https://eth.llamarpc.com",
    chain: :ethereum,
    trusted: true,
    name: "llamarpc_eth"
  },
  %{
    url: "https://eth.getblock.io/2e50183d-4f7d-4bd4-809b-17a61b87fd11/mainnet/",
    chain: :ethereum,
    trusted: false,
    name: "getblock_eth"
  },
  %{
    url: "https://btc.getblock.io/2e50183d-4f7d-4bd4-809b-17a61b87fd11/mainnet/",
    chain: :bitcoin,
    trusted: false,
    name: "getblock_btc"
  }
]

config :node_watch, :integrity_check_enabled, true

config :node_watch, NodeWatch.Integrity.Checker,
  ethereum: [
    %{
      method: "eth_chainId"
    },
    %{
      method: "eth_getBalance",
      params: ["0xbe0eb53f46cd790cd13851d5eff43d12404d33e8", "0xfbdef4"]
    }
    # %{
    #   method: "eth_getCode", #TODO
    #   params: ["earliest", false]
    # }
    # %{
    #   method: "eth_call",
    #   params: [%{
    #     to: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
    #     data: "0x18160ddd"
    #   }, "latest"]
    # }
  ],
  # TODO add methods
  bitcoin: [
    %{
      method: "getblockchaininfo"
    },
    %{
      method: "total balance"
    }
  ]

config :node_watch, :max_blocks_behind, 15

# Set initial check interval in seconds
# config :node_watch, :initial_check_interval, 450
config :node_watch, :initial_check_interval, 10

config :node_watch, NodeWatch.RPCClient,
  jsonrpc_version: [
    bitcoin: "1.0",
    ethereum: "2.0"
  ],
  http_timeout: 60_000
