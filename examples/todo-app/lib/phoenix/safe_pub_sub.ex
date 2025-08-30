defmodule SafePubSub do
  def subscribeWithConverter() do
    fn topic, topic_converter -> pubsub_module = Module.concat([Application.get_application(__MODULE__), "PubSub"])
topic_string = topic_converter.(topic)
Phoenix.PubSub.subscribe(pubsub_module, topic_string) end
  end
  def broadcastWithConverters() do
    fn topic, message, topic_converter, message_converter -> pubsub_module = Module.concat([Application.get_application(__MODULE__), "PubSub"])
topic_string = topic_converter.(topic)
message_payload = message_converter.(message)
Phoenix.PubSub.broadcast(pubsub_module, topic_string, message_payload) end
  end
  def parseWithConverter() do
    fn msg, message_parser -> {:unknown, msg} end
  end
  def addTimestamp() do
    fn payload -> if (payload == nil) do
  payload = %{}
end
Reflect.set_field(payload, "timestamp", Date.now().getTime())
payload end
  end
  def isValidMessage() do
    fn msg -> msg != nil && Reflect.has_field(msg, "type") && Reflect.field(msg, "type") != nil end
  end
  def createUnknownMessageError() do
    fn message_type -> "Unknown PubSub message type: \"" + message_type + "\". Check your message enum definitions." end
  end
  def createMalformedMessageError() do
    fn msg -> msg_str = try do
  replacer = nil
  space = nil
  JsonPrinter.print(msg, replacer, space)
rescue
  e ->
    "unparseable message"
end
"Malformed PubSub message: " + msg_str + ". Expected message with \"type\" field." end
  end
end