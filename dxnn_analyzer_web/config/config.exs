import Config

config :dxnn_analyzer_web,
  generators: [timestamp_type: :utc_datetime]

config :dxnn_analyzer_web, DxnnAnalyzerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: DxnnAnalyzerWeb.ErrorHTML],
    layout: false
  ],
  pubsub_server: DxnnAnalyzerWeb.PubSub,
  live_view: [signing_salt: "dxnn_analyzer_secret"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
