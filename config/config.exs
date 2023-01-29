import Config

config :node_watch,
  ecto_repos: [NodeWatch.Repo]

config :node_watch, NodeWatchWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: NodeWatchWeb.ErrorHTML, json: NodeWatchWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: NodeWatch.PubSub,
  live_view: [signing_salt: "1oL41nh5"]

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

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"

# TEST TASK CONFIGS

# Configures Elixir's Logger
config :logger,
  backends: [:console, {LoggerFileBackend, :info}],
  level: :debug

config :logger, :info,
  path: "logs/availability.log",
  format: "$date; $time; [$level]; $message \n",
  level: :info

# Specs for the nodes to be monitored
# The name is used to identify the node in the UI
config :node_watch, :nodes, [
  %{
    url: "https://eth.llamarpc.com",
    chain: :ethereum,
    trusted: true,
    name: "llamarpc_eth"
  },
  %{
    url: "https://endpoints.omniatech.io/v1/eth/mainnet/public",
    chain: :ethereum,
    trusted: false,
    name: "omnia_eth"
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
  },
  %{
    url: "https://endpoints.omniatech.io/v1/btc/mainnet/6b0a4848e1d94f84b740d28045638995",
    chain: :bitcoin,
    trusted: true,
    name: "omnia_btc"
  }
]

# Integrity check config for switching the module on/off
config :node_watch, :integrity_check_enabled, true

# Integrity check methods
config :node_watch, :integrity_check_methods,
  ethereum: [
    # Get block by number
    %{
      method: "eth_getBlockByNumber",
      params: ["0xfbf2f2", false]
    },
    # Get ETH balance on name Binance account
    %{
      method: "eth_getBalance",
      params: ["0xbe0eb53f46cd790cd13851d5eff43d12404d33e8", "0xfbf2f2"]
    },
    # BalanceOf call to Tether treasury account for ETH USDT
    %{
      method: "eth_call",
      params: [
        %{
          to: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
          data: "0x70a082310000000000000000000000005754284f345afc66a98fbb0a0afe71e0f007b949"
        },
        "0xfbf2f2"
      ]
    },
    %{
      method: "eth_getTransactionReceipt",
      params: ["0x3c1fe23ac4e8660b9f75a02e0e15cd4be145fbb3489092d1468935100ed0e492"]
    }
  ],
  bitcoin: [
    %{
      method: "getblock",
      params: ["0000000000000000000607dcc1cbbfc7a1a3ba5fc4720bf3abf28d07a66f8365"]
    }
  ]

config :node_watch, :max_blocks_behind, 15

# Set initial check interval in seconds
config :node_watch, :initial_check_interval, 450

config :node_watch, NodeWatch.RPCClient,
  jsonrpc_version: [
    bitcoin: "1.0",
    ethereum: "2.0"
  ],
  http_timeout: 60_000
