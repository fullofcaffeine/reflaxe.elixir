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
  @doc """
    Type-safe subscribe to a topic with conversion

    @param topic Application-specific topic enum
    @param topicConverter Function to convert topic to string
    @return Result indicating success or failure
  """
  @spec subscribe_with_converter(T.t(), Function.t()) :: Result.t()
  def subscribe_with_converter(topic, topic_converter) do
    topic_string = topic_converter.(topic)
    Phoenix.PubSub.subscribe(TodoApp.PubSub, topic_string, %{})
  end

  @doc """
    Type-safe broadcast with topic and message conversion

    @param topic Application-specific topic enum
    @param message Application-specific message enum
    @param topicConverter Function to convert topic to string
    @param messageConverter Function to convert message to Dynamic
    @return Result indicating success or failure
  """
  @spec broadcast_with_converters(T.t(), M.t(), Function.t(), Function.t()) :: Result.t()
  def broadcast_with_converters(topic, message, topic_converter, message_converter) do
    topic_string = topic_converter.(topic)
    message_payload = message_converter.(message)
    Phoenix.PubSub.broadcast(TodoApp.PubSub, topic_string, message_payload)
  end

  @doc """
    Parse incoming PubSub message with application-specific parser

    @param msg Raw Dynamic message from PubSub
    @param messageParser Application-specific message parser
    @return Parsed message or None if parsing failed
  """
  @spec parse_with_converter(term(), Function.t()) :: Option.t()
  def parse_with_converter(msg, message_parser) do
    message_parser.(msg)
  end

  @doc """
    Utility function to add timestamp to message payload

  """
  @spec add_timestamp(term()) :: term()
  def add_timestamp(payload) do
    if (payload == nil) do
      payload = %{}
    end
    Reflect.set_field(payload, "timestamp", Date.now().get_time())
    payload
  end

  @doc """
    Utility function to validate message structure

    @param msg Message to validate
    @return true if message has required fields
  """
  @spec is_valid_message(term()) :: boolean()
  def is_valid_message(msg) do
    msg != nil && Reflect.has_field(msg, "type") && Reflect.field(msg, "type") != nil
  end

  @doc """
    Create a standard error message for unknown message types

  """
  @spec create_unknown_message_error(String.t()) :: String.t()
  def create_unknown_message_error(message_type) do
    "Unknown PubSub message type: \"" <> message_type <> "\". Check your message enum "
  end

  @doc """
    Create a standard error message for malformed messages

  """
  @spec create_malformed_message_error(term()) :: String.t()
  def create_malformed_message_error(msg) do
    temp_string = nil
    try do
      replacer = nil
    space = nil
    temp_string = JsonPrinter.print(msg, replacer, space)
    rescue
      e ->
        temp_string = "unparseable message"
    end
    "Malformed PubSub message: " <> temp_string <> ". Expected message with \"type\" field."
  end

end
