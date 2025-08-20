defmodule TodoPubSubTopic do
  @moduledoc """
  TodoPubSubTopic enum generated from Haxe
  
  
   * Type-safe PubSub topics for the todo application
   * 
   * Adding new topics requires:
   * 1. Add enum case here
   * 2. Add case to topicToString function
   * 3. Compiler ensures exhaustiveness
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :todo_updates |
    :user_activity |
    :system_notifications

  @doc "Creates todo_updates enum value"
  @spec todo_updates() :: :todo_updates
  def todo_updates(), do: :todo_updates

  @doc "Creates user_activity enum value"
  @spec user_activity() :: :user_activity
  def user_activity(), do: :user_activity

  @doc "Creates system_notifications enum value"
  @spec system_notifications() :: :system_notifications
  def system_notifications(), do: :system_notifications

  # Predicate functions for pattern matching
  @doc "Returns true if value is todo_updates variant"
  @spec is_todo_updates(t()) :: boolean()
  def is_todo_updates(:todo_updates), do: true
  def is_todo_updates(_), do: false

  @doc "Returns true if value is user_activity variant"
  @spec is_user_activity(t()) :: boolean()
  def is_user_activity(:user_activity), do: true
  def is_user_activity(_), do: false

  @doc "Returns true if value is system_notifications variant"
  @spec is_system_notifications(t()) :: boolean()
  def is_system_notifications(:system_notifications), do: true
  def is_system_notifications(_), do: false

end
