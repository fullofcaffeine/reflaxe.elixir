defmodule Todo do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    Todo struct generated from Haxe

     * Todo schema for managing tasks
  """

  defstruct [:id, :title, :description, :due_date, :user_id, completed: false, priority: "medium", tags: nil]

  @type t() :: %__MODULE__{
    id: integer() | nil,
    title: String.t() | nil,
    description: String.t() | nil,
    completed: boolean(),
    priority: String.t(),
    due_date: Null.t() | nil,
    tags: Array.t(),
    user_id: integer() | nil
  }

  @doc "Creates a new struct instance"
  @spec new() :: t()
  def new() do
    %__MODULE__{
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Static functions
  @doc "Generated from Haxe changeset"
  def changeset(todo, params) do
    _changeset = Ecto.Changeset.cast_changeset(todo, params, ["title", "description", "completed", "priority", "due_date", "tags", "user_id"])

    _changeset = Ecto.Changeset.validate_required(_changeset, ["title", "user_id"])

    _changeset = Ecto.Changeset.validate_length(_changeset, "title", %{min: 3, max: 200})

    _changeset = Ecto.Changeset.validate_length(_changeset, "description", %{max: 1000})

    priority_values = [ChangesetValue.string_value("low"), ChangesetValue.string_value("medium"), ChangesetValue.string_value("high")]

    _changeset = Ecto.Changeset.validate_inclusion(_changeset, "priority", priority_values)

    _changeset = Ecto.Changeset.foreign_key_constraint(_changeset, "user_id")

    _changeset
  end

  @doc "Generated from Haxe toggle_completed"
  def toggle_completed(todo) do
    _params = StringMap.new()

    _value = ChangesetValue.bool_value(not todo.completed)

    _params = Map.put(_params, "completed", _value)

    Todo.changeset(todo, _params)
  end

  @doc "Generated from Haxe update_priority"
  def update_priority(todo, priority) do
    _params = StringMap.new()

    _value = ChangesetValue.string_value(priority)

    _params = Map.put(_params, "priority", _value)

    Todo.changeset(todo, _params)
  end

  @doc "Generated from Haxe add_tag"
  def add_tag(todo, tag) do
    temp_array = nil

    if ((todo.tags != nil)), do: temp_array = todo.tags, else: temp_array = []

    temp_array = temp_array ++ [tag]

    _params = StringMap.new()

    g_array = []

    g_counter = 0

    (fn loop ->
      if ((g_counter < temp_array.length)) do
            v = Enum.at(temp_array, g_counter)
        g_counter + 1
        g_array = g_array ++ [ChangesetValue.string_value(v)]
        loop.()
      end
    end).()

    _value = ChangesetValue.array_value(g_array)

    _params = Map.put(_params, "tags", _value)

    Todo.changeset(todo, _params)
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
