defmodule PubSubMessageProvider do
  @moduledoc """
  PubSubMessageProvider behavior generated from Haxe interface
  
  
 * Base interface for application-specific PubSub messages
 * 
 * Applications should define their own message enums and provide
 * parsing functions for incoming messages.
 
  """

  @callback parse_message(term()) :: Option.t()
  @callback message_to_elixir(M.t()) :: term()
end
