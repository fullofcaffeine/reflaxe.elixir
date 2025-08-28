defmodule TypeSafeChildSpecBuilder do
  @moduledoc """
    TypeSafeChildSpecBuilder module generated from Haxe

     * Builder functions for common child spec patterns
     *
     * These provide convenient factory methods for creating type-safe child specs
     * with sensible defaults and proper Phoenix conventions.
  """

  # Static functions
  @doc "Generated from Haxe pubsub"
  def pubsub(app_name) do
    {Phoenix.PubSub, name: _app_name <> ".PubSub"}
  end

  @doc "Generated from Haxe repo"
  def repo(_app_name, config \\ nil) do
    TodoApp.Repo
  end

  @doc "Generated from Haxe endpoint"
  def endpoint(_app_name, port \\ nil, config \\ nil) do
    temp_number = nil

    temp_number = nil

    tmp = port
    if ((tmp != nil)), do: temp_number = tmp, else: temp_number = 4000

    TodoAppWeb.Endpoint
  end

  @doc "Generated from Haxe telemetry"
  def telemetry(_app_name, config \\ nil) do
    TodoAppWeb.Telemetry
  end

  @doc "Generated from Haxe presence"
  def presence(app_name, pubsub_name \\ nil) do
    temp_string = nil

    temp_string = nil

    tmp = pubsub_name
    if ((tmp != nil)), do: temp_string = tmp, else: temp_string = "" <> _app_name <> ".PubSub"

    {:presence, %{"name" => "" <> _app_name <> ".Presence", "pubsub_server" => temp_string}}
  end

  @doc "Generated from Haxe worker"
  def worker(module, args) do
    {:custom, module, _args, :permanent, ShutdownType.timeout(5000)}
  end

  @doc "Generated from Haxe supervisor"
  def supervisor(module, args) do
    {:custom, module, _args, :permanent, :infinity}
  end

end
