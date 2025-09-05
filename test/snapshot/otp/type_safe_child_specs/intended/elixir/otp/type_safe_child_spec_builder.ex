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
    :TypeSafeChildSpec.PubSub(app_name + ".PubSub")
  end

  @doc "Generated from Haxe repo"
  def repo(_app_name, config \\ nil) do
    :TypeSafeChildSpec.Repo(config)
  end

  @doc "Generated from Haxe endpoint"
  def endpoint(_app_name, port \\ nil, config \\ nil) do
    temp_number = nil

    temp_number = nil
    tmp = port
    if (tmp != nil) do
      temp_number = tmp
    else
      temp_number = 4000
    end
    :TypeSafeChildSpec.Endpoint(temp_number, config)
  end

  @doc "Generated from Haxe telemetry"
  def telemetry(_app_name, config \\ nil) do
    :TypeSafeChildSpec.Telemetry(config)
  end

  @doc "Generated from Haxe presence"
  def presence(app_name, pubsub_name \\ nil) do
    temp_string = nil

    temp_string = nil
    tmp = pubsub_name
    if (tmp != nil) do
      temp_string = tmp
    else
      temp_string = "" + app_name + ".PubSub"
    end
    :TypeSafeChildSpec.Presence(%{:name => "" + app_name + ".Presence", :pubsub_server => temp_string})
  end

  @doc "Generated from Haxe worker"
  def worker(module, args) do
    :TypeSafeChildSpec.Custom(module, args, :RestartType.Permanent, :ShutdownType.Timeout(5000))
  end

  @doc "Generated from Haxe supervisor"
  def supervisor(module, args) do
    :TypeSafeChildSpec.Custom(module, args, :RestartType.Permanent, :ShutdownType.Infinity)
  end

end
