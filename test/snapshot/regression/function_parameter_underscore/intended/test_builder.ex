defmodule TestBuilder do
  @moduledoc """
    TestBuilder module generated from Haxe

     * Test case specifically for TypeSafeChildSpecBuilder pattern
  """

  # Static functions
  @doc "Generated from Haxe pubsub"
  def pubsub(app_name) do
    app_name <> ".PubSub"
  end

  @doc "Generated from Haxe endpoint"
  def endpoint(app_name, port \\ nil) do
    temp_maybe_number = nil

    if ((port != nil)), do: temp_maybe_number = port, else: temp_maybe_number = 4000

    actual_port = temp_maybe_number

    app_name <> ".Endpoint on port " <> to_string(actual_port)
  end

end
