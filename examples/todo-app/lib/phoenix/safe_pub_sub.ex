defmodule SafePubSub do
  @moduledoc """
    SafePubSub module generated from Haxe

     * Framework-level SafePubSub operations
     *
     * This class provides the core infrastructure for type-safe PubSub
     * operations. Applications extend this by providing their own
     * topic and message type definitions.
  """

  # Static functions
  @doc "Generated from Haxe subscribeWithConverter"
  def subscribe_with_converter(topic, topic_converter) do
    pubsub_module = Module.concat([Application.get_application(__MODULE__), "PubSub"])
    topic_string = topic_converter.(topic)
    Phoenix.PubSub.subscribe(pubsub_module, topic_string)
  end

  @doc "Generated from Haxe broadcastWithConverters"
  def broadcast_with_converters(topic, message, topic_converter, message_converter) do
    pubsub_module = Module.concat([Application.get_application(__MODULE__), "PubSub"])
    topic_string = topic_converter.(topic)
    message_payload = message_converter.(message)
    Phoenix.PubSub.broadcast(pubsub_module, topic_string, message_payload)
  end

  @doc "Generated from Haxe parseWithConverter"
  def parse_with_converter(msg, message_parser) do
    message_parser.(msg)
  end

  @doc "Generated from Haxe addTimestamp"
  def add_timestamp(payload) do
    if (payload == nil) do
      payload = %{}
    end
    :Reflect.setField(payload, "timestamp", :Date.now().getTime())
    payload
  end

  @doc "Generated from Haxe isValidMessage"
  def is_valid_message(msg) do
    msg != nil && :Reflect.hasField(msg, "type") && :Reflect.field(msg, "type") != nil
  end

  @doc "Generated from Haxe createUnknownMessageError"
  def create_unknown_message_error(message_type) do
    "Unknown PubSub message type: \"" + message_type + "\". Check your message enum "
  end

  @doc "Generated from Haxe createMalformedMessageError"
  def create_malformed_message_error(msg) do
    temp_string = nil

    temp_string = nil
    try do
      replacer = nil
      space = nil
      temp_string = :JsonPrinter.print(msg, replacer, space)
    rescue
      e ->
        temp_string = "unparseable message"
    end
    "Malformed PubSub message: " + temp_string + ". Expected message with \"type\" field."
  end

end
