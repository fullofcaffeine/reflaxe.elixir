defmodule SafePubSub do
  def subscribeWithConverter(topic, topic_converter) do
    pubsub_module = Module.concat([Application.get_application(__MODULE__), "PubSub"])
    topic_string = topic_converter.(topic)
    Phoenix.PubSub.subscribe(pubsub_module, topic_string)
  end
  def broadcastWithConverters(topic, message, topic_converter, message_converter) do
    pubsub_module = Module.concat([Application.get_application(__MODULE__), "PubSub"])
    topic_string = topic_converter.(topic)
    message_payload = message_converter.(message)
    Phoenix.PubSub.broadcast(pubsub_module, topic_string, message_payload)
  end
  def parseWithConverter(msg, message_parser) do
    {:ModuleRef, msg}
  end
  def addTimestamp(payload) do
    if (payload == nil) do
      payload = %{}
    end
    Reflect.set_field(payload, "timestamp", Date.now().getTime())
    payload
  end
  def isValidMessage(msg) do
    msg != nil && Reflect.has_field(msg, "type") && Reflect.field(msg, "type") != nil
  end
  def createUnknownMessageError(message_type) do
    "Unknown PubSub message type: \"" + message_type + "\". Check your message enum definitions."
  end
  def createMalformedMessageError(msg) do
    msg_str = try do
  replacer = nil
  space = nil
  JsonPrinter.print(msg, replacer, space)
rescue
  e ->
    "unparseable message"
end
    "Malformed PubSub message: " + msg_str + ". Expected message with \"type\" field."
  end
end