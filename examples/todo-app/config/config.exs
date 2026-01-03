import Config

# Configure Ecto repositories
config :todo_app,
  ecto_repos: [TodoApp.Repo]

# Configures the endpoint
config :todo_app, TodoAppWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: TodoAppWeb.ErrorHTML, json: TodoAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: TodoApp.PubSub,
  live_view: [signing_salt: "secret_salt"]

# Configure Presence to use the app's PubSub server
config :todo_app, TodoAppWeb.Presence,
  pubsub_server: TodoApp.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Email delivery (Swoosh)
#
# The todo-app uses a lightweight "invite by email" flow. In dev/e2e we use the
# Local adapter so you can preview emails in the browser (via /dev/mailbox).
config :todo_app, TodoApp.Mailer,
  adapter: Swoosh.Adapters.Local

# Configure esbuild for Haxe→JavaScript + Phoenix integration
config :esbuild,
  version: "0.19.8",
  todo_app: [
    args: ~w(
      js/phoenix_app.js
      --bundle
      --target=es2017
      --outdir=../priv/static/assets
      --external:/fonts/*
      --external:/images/*
      --tree-shaking=true
      --splitting=false
      --format=iife
      --global-name=TodoApp
      --sourcemap=external
      --loader:.hx=text
    ),
    cd: Path.expand("../assets", __DIR__),
    env: %{
      "NODE_PATH" => Path.expand("../deps", __DIR__),
      "NODE_ENV" => to_string(Mix.env())
    }
  ]

# Configure Tailwind CSS processing
config :tailwind,
  version: "3.3.6",
  todo_app: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
      --postcss
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config
import_config "#{config_env()}.exs"
