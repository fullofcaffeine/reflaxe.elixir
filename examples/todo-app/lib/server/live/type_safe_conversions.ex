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
  @doc """
    Convert EventParams to ChangesetParams with full type safety

    EventParams comes from Phoenix LiveView events with Null<String> fields.
    ChangesetParams expects Map<String, ChangesetValue> for Ecto operations.

    @param params EventParams from LiveView event handling
    @return ChangesetParams suitable for Ecto changeset operations
  """
  @spec event_params_to_changeset_params(EventParams.t()) :: ChangesetParams.t()
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

  @doc """
    Convert raw todo creation parameters to ChangesetParams

    Used when creating new todos with structured data rather than event params.

    @param title Todo title
    @param description Todo description
    @param priority Priority level
    @param due_date Due date string
    @param tags Tags string (comma-separated)
    @param user_id User ID for ownership
    @return Type-safe ChangesetParams
  """
  @spec create_todo_params(String.t(), Null.t(), String.t(), Null.t(), Null.t(), integer()) :: ChangesetParams.t()
  def create_todo_params(title, description, priority, due_date, tags, user_id) do
    changeset_params = Haxe.Ds.StringMap.new()
    (
          value = ChangesetValue.string_value(title)
          changeset_params.set("title", value)
        )
    (
          value = ChangesetValue.string_value(priority)
          changeset_params.set("priority", value)
        )
    (
          value = ChangesetValue.int_value(user_id)
          changeset_params.set("user_id", value)
        )
    (
          value = ChangesetValue.bool_value(false)
          changeset_params.set("completed", value)
        )
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

  @doc """
    Validate that EventParams contains required fields for todo creation

    @param params EventParams from LiveView
    @return true if all required fields are present and valid
  """
  @spec validate_todo_creation_params(EventParams.t()) :: boolean()
  def validate_todo_creation_params(params) do
    ((params.title != nil) && (params.title.length > 0))
  end

  @doc """
    Create a complete TodoLiveAssigns object with all required fields

    Instead of partial objects that fail assign_multiple, create complete
    assigns structures with proper defaults for missing fields.

    @param base Base assigns to extend (optional)
    @param updates Fields to update
    @return Complete TodoLiveAssigns object
  """
  @spec create_complete_assigns(Null.t(), Null.t(), Null.t(), Null.t(), Null.t(), Null.t(), Null.t(), Null.t(), Null.t()) :: TodoLiveAssigns.t()
  def create_complete_assigns(base, todos, filter, sort_by, current_user, editing_todo, show_form, search_query, selected_tags) do
    temp_user = nil
    temp_string2 = nil
    temp_string1 = nil
    temp_string = nil
    temp_maybe_todo = nil
    temp_bool = nil
    temp_array1 = nil
    temp_array = nil

    if ((todos != nil)) do
          temp_array = todos
        else
          temp_array = if (((base != nil))), do: base.todos, else: []
        end

    if ((filter != nil)) do
          temp_string = filter
        else
          temp_string = if (((base != nil))), do: base.filter, else: "all"
        end

    if ((sort_by != nil)) do
          temp_string1 = sort_by
        else
          temp_string1 = if (((base != nil))), do: base.sort_by, else: "created"
        end

    if ((current_user != nil)) do
          temp_user = current_user
        else
          temp_user = if (((base != nil))), do: base.current_user, else: TypeSafeConversions.create_default_user()
        end

    if ((editing_todo != nil)) do
          temp_maybe_todo = editing_todo
        else
          temp_maybe_todo = if (((base != nil))), do: base.editing_todo, else: nil
        end

    if ((show_form != nil)) do
          temp_bool = show_form
        else
          temp_bool = if (((base != nil))), do: base.show_form, else: false
        end

    if ((search_query != nil)) do
          temp_string2 = search_query
        else
          temp_string2 = if (((base != nil))), do: base.search_query, else: ""
        end

    if ((selected_tags != nil)) do
          temp_array1 = selected_tags
        else
          temp_array1 = if (((base != nil))), do: base.selected_tags, else: []
        end
    assigns = %{"todos" => temp_array, "filter" => temp_string, "sort_by" => temp_string1, "current_user" => temp_user, "editing_todo" => temp_maybe_todo, "show_form" => temp_bool, "search_query" => temp_string2, "selected_tags" => temp_array1, "total_todos" => 0, "completed_todos" => 0, "pending_todos" => 0}
    %{assigns | total_todos: assigns.todos.length}
    %{assigns | completed_todos: TypeSafeConversions.count_completed(assigns.todos)}
    %{assigns | pending_todos: (assigns.total_todos - assigns.completed_todos)}
    assigns
  end

  @doc """
    Create a default user for fallback scenarios

  """
  @spec create_default_user() :: User.t()
  def create_default_user() do
    %{"id" => 1, "name" => "Default User", "email" => "default@example.com", "password_hash" => "default_hash", "confirmed_at" => nil, "last_login_at" => nil, "active" => true}
  end

  @doc """
    Count completed todos in array

  """
  @spec count_completed(Array.t()) :: integer()
  def count_completed(todos) do
    (
          count = 0
          g_counter = 0
          Enum.each(g_array, fn todo -> 
      if todo.completed do
          count + 1
        end
    end)
          count
        )
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
