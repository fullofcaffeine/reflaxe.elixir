defmodule SafePubSub do
  def subscribeWithConverter(topic, topicConverter) do
    pubsub_module = Module.concat([Application.get_application(__MODULE__), "PubSub"])
    topic_string = topic_converter.(topic)
    Phoenix.PubSub.subscribe(pubsubModule, topicString)
  end
  def broadcastWithConverters(topic, message, topicConverter, messageConverter) do
    pubsub_module = Module.concat([Application.get_application(__MODULE__), "PubSub"])
    topic_string = topic_converter.(topic)
    message_payload = message_converter.(message)
    Phoenix.PubSub.broadcast(pubsubModule, topicString, messagePayload)
  end
  def parseWithConverter(msg, messageParser) do
    {:unknown, msg}
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
  def createUnknownMessageError(messageType) do
    "Unknown PubSub message type: \"" + messageType + "\". Check your message enum definitions."
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
    "Malformed PubSub message: " + msgStr + ". Expected message with \"type\" field."
  end
end