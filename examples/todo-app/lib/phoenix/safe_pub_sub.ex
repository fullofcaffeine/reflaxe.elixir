defmodule Phoenix.SafePubSub do
  def subscribe_with_converter(topic, topic_converter) do
    pubsub_module = Module.concat([Application.get_application(__MODULE__), "PubSub"])
    topic_string = topic_converter.(topic)
    Phoenix.PubSub.subscribe(pubsub_module, topic_string)
  end
  def broadcast_with_converters(topic, message, topic_converter, message_converter) do
    pubsub_module = Module.concat([Application.get_application(__MODULE__), "PubSub"])
    topic_string = topic_converter.(topic)
    message_payload = message_converter.(message)
    Phoenix.PubSub.broadcast(pubsub_module, topic_string, message_payload)
  end
  def parse_with_converter(msg, message_parser) do
    message_parser.(msg)
  end
  def add_timestamp(payload) do
    if (payload == nil) do
      payload = %{}
    end
    payload = Map.put(payload, "timestamp", DateTime.utc_now() |> DateTime.to_unix(:millisecond))
    payload
  end
  def is_valid_message(msg) do
    msg != nil && Map.has_key?(msg, "type") && Map.get(msg, "type") != nil
  end
  def create_unknown_message_error(message_type) do
    "Unknown PubSub message type: \"" <> message_type <> "\". Check your message enum definitions."
  end
  def create_malformed_message_error(msg) do
    msg_str = try do
  replacer = nil
  space = nil
  JsonPrinter.print(msg, replacer, space)
rescue
  e ->
    "unparseable message"
end
    "Malformed PubSub message: " <> msg_str <> ". Expected message with \"type\" field."
  end
end