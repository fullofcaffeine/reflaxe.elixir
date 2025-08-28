defmodule TestTopic do
  @moduledoc """
  TestTopic enum generated from Haxe
  
  
   * Test case for temp_result switch expression compilation bug
   * 
   * This test reproduces the exact issue found in TodoPubSub.topicToString:
   * - Switch expressions that should return values directly
   * - Instead generate temp_result = nil wrapper but case branches return directly
   * - Should either: optimize away the temp_result OR make branches assign to temp_result
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :topic_a |
    :topic_b |
    :topic_c

  @doc "Creates topic_a enum value"
  @spec topic_a() :: :topic_a
  def topic_a(), do: :topic_a

  @doc "Creates topic_b enum value"
  @spec topic_b() :: :topic_b
  def topic_b(), do: :topic_b

  @doc "Creates topic_c enum value"
  @spec topic_c() :: :topic_c
  def topic_c(), do: :topic_c

  # Predicate functions for pattern matching
  @doc "Returns true if value is topic_a variant"
  @spec is_topic_a(t()) :: boolean()
  def is_topic_a(:topic_a), do: true
  def is_topic_a(_), do: false

  @doc "Returns true if value is topic_b variant"
  @spec is_topic_b(t()) :: boolean()
  def is_topic_b(:topic_b), do: true
  def is_topic_b(_), do: false

  @doc "Returns true if value is topic_c variant"
  @spec is_topic_c(t()) :: boolean()
  def is_topic_c(:topic_c), do: true
  def is_topic_c(_), do: false

end
