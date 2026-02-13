import Config

dev_port =
  case System.get_env("PORT") do
    nil ->
      4000

    val ->
      case Integer.parse(val) do
        {int, _} -> int
        :error -> 4000
      end
  end

config :elixir_first_liveview, ElixirFirstLiveviewWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: dev_port],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: System.get_env("DEV_SECRET_KEY_BASE") || String.duplicate("a", 64),
  watchers: [
    mix: [
      "haxe.watch",
      "--hxml",
      "build-client.hxml",
      "--dirs",
      "src_haxe/client",
      "--debounce",
      "150",
      "--promote",
      "assets/js/_hx_app_tmp.js:assets/js/hx_app.js,assets/js/_hx_app_tmp.js.map:assets/js/hx_app.js.map",
      cd: Path.expand("../", __DIR__)
    ],
    esbuild: {Esbuild, :install_and_run, [:elixir_first_liveview, ~w(--sourcemap=inline --watch)]}
  ]

config :elixir_first_liveview, ElixirFirstLiveviewWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/elixir_first_liveview_web/(live|views)/.*(ex)$",
      ~r"lib/elixir_first_liveview_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
