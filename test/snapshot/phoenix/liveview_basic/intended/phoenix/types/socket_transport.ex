defmodule SocketTransport do
  @moduledoc """
  SocketTransport enum generated from Haxe
  
  
   * LiveView socket transport types
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :web_socket |
    :long_poll

  @doc "Creates web_socket enum value"
  @spec web_socket() :: :web_socket
  def web_socket(), do: :web_socket

  @doc "Creates long_poll enum value"
  @spec long_poll() :: :long_poll
  def long_poll(), do: :long_poll

  # Predicate functions for pattern matching
  @doc "Returns true if value is web_socket variant"
  @spec is_web_socket(t()) :: boolean()
  def is_web_socket(:web_socket), do: true
  def is_web_socket(_), do: false

  @doc "Returns true if value is long_poll variant"
  @spec is_long_poll(t()) :: boolean()
  def is_long_poll(:long_poll), do: true
  def is_long_poll(_), do: false

end
