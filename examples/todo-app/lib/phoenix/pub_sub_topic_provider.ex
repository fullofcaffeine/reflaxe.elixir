defmodule PubSubTopicProvider do
  @moduledoc """
  PubSubTopicProvider behavior generated from Haxe interface
  
  
 * Base interface for application-specific PubSub topics
 * 
 * Applications should define their own topic enums and provide
 * a topicToString conversion function.
 
  """

  @callback topic_to_string(T.t()) :: String.t()
end
