defmodule TypeSafeConversions do
  @moduledoc """
    TypeSafeConversions module generated from Haxe

     * Type-safe conversion utilities for Phoenix LiveView operations
     *
     * This module provides compile-time validated conversions between different
     * parameter types, eliminating unsafe casts and ensuring data integrity.
     *
     * ## Design Philosophy
     *
     * Instead of using Dynamic types or unsafe casts, we create explicit conversion
     * functions that validate and transform data in a type-safe manner.
     *
     * ## Benefits
     * - **Compile-time validation**: All conversions are type-checked
     * - **No data loss**: Explicit handling of all field types
     * - **Error tracking**: Clear handling of conversion failures
     * - **Maintainable**: Easy to extend and modify conversion logic
  """

  # Static functions
  @doc "Generated from Haxe eventParamsToChangesetParams"
  def event_params_to_changeset_params(params) do
    changeset_params = Haxe.Ds.StringMap.new()
    if ((params.title != nil)) do
          (
          value = ChangesetValue.string_value(params.title)
          changeset_params.set("title", value)
        )
        end
    if ((params.description != nil)) do
          (
          value = ChangesetValue.string_value(params.description)
          changeset_params.set("description", value)
        )
        end
    if ((params.priority != nil)) do
          (
          value = ChangesetValue.string_value(params.priority)
          changeset_params.set("priority", value)
        )
        end
    if ((params.due_date != nil)) do
          (
          value = ChangesetValue.string_value(params.due_date)
          changeset_params.set("due_date", value)
        )
        end
    if ((params.tags != nil)) do
          (
          value = ChangesetValue.string_value(params.tags)
          changeset_params.set("tags", value)
        )
        end
    if ((params.completed != nil)) do
          (
          value = ChangesetValue.bool_value(params.completed)
          changeset_params.set("completed", value)
        )
        end
    changeset_params
  end

  @doc "Generated from Haxe createTodoParams"
  def create_todo_params(title, description, priority, due_date, tags, user_id) do
    changeset_params = Haxe.Ds.StringMap.new()
    value = ChangesetValue.string_value(title)
    changeset_params.set("title", value)
    value = ChangesetValue.string_value(priority)
    changeset_params.set("priority", value)
    value = ChangesetValue.int_value(user_id)
    changeset_params.set("user_id", value)
    value = ChangesetValue.bool_value(false)
    changeset_params.set("completed", value)
    if ((description != nil)) do
          (
          value = ChangesetValue.string_value(description)
          changeset_params.set("description", value)
        )
        end
    if ((due_date != nil)) do
          (
          value = ChangesetValue.string_value(due_date)
          changeset_params.set("due_date", value)
        )
        end
    if ((tags != nil)) do
          (
          value = ChangesetValue.string_value(tags)
          changeset_params.set("tags", value)
        )
        end
    changeset_params
  end

  @doc "Generated from Haxe validateTodoCreationParams"
  def validate_todo_creation_params(params) do
    ((params.title != nil) && (params.title.length > 0))
  end

  @doc "Generated from Haxe createCompleteAssigns"
  def create_complete_assigns(base \\ nil, todos \\ nil, filter \\ nil, sort_by \\ nil, current_user \\ nil, editing_todo \\ nil, show_form \\ nil, search_query \\ nil, selected_tags \\ nil) do
    temp_string1 = nil
    temp_user = nil
    temp_maybe_todo = nil
    temp_bool = nil
    temp_string2 = nil
    temp_array = nil
    temp_string = nil
    temp_array1 = nil


        temp_string1 = nil
        temp_user = nil
        temp_maybe_todo = nil
        temp_bool = nil
        temp_string2 = nil
        
        assigns = %{"todos" => temp_array, "filter" => temp_string, "sort_by" => temp_string1, "current_user" => temp_user, "editing_todo" => temp_maybe_todo, "show_form" => temp_bool, "search_query" => temp_string2, "selected_tags" => temp_array1, "total_todos" => 0, "completed_todos" => 0, "pending_todos" => 0}
        %{assigns | total_todos: assigns.todos.length}
        %{assigns | completed_todos: TypeSafeConversions.count_completed(assigns.todos)}
        %{assigns | pending_todos: (assigns.total_todos - assigns.completed_todos)}
        assigns
  end

  @doc "Generated from Haxe createDefaultUser"
  def create_default_user() do
    %{"id" => 1, "name" => "Default User", "email" => "default@example.com", "password_hash" => "default_hash", "confirmed_at" => nil, "last_login_at" => nil, "active" => true}
  end

  @doc "Generated from Haxe countCompleted"
  def count_completed(todos) do
    count = 0
    g_counter = 0
    Enum.each(g_array, fn todo -> 
      if todo.completed do
          count + 1
        end
    end)
    count
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
