import Config

config :dxnn_analyzer_web, DxnnAnalyzerWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dxnn_analyzer_secret_key_base_for_development_only_change_in_production",
  watchers: []

config :dxnn_analyzer_web, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
