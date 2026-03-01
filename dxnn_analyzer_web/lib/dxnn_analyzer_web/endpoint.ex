defmodule DxnnAnalyzerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :dxnn_analyzer_web

  @session_options [
    store: :cookie,
    key: "_dxnn_analyzer_web_key",
    signing_salt: "dxnn_analyzer",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :dxnn_analyzer_web,
    gzip: false,
    only: DxnnAnalyzerWeb.static_paths()

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug DxnnAnalyzerWeb.Router
end
