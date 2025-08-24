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
  @doc "Function changeset"
  @spec changeset(Todo.t(), ChangesetParams.t()) :: Ecto.Changeset.t()
  def changeset(todo, params) do
    changeset = Changeset.cast_changeset(todo, params, ["title", "description", "completed", "priority", "due_date", "tags", "user_id"])
    changeset = Changeset.validate_required(changeset, ["title", "user_id"])
    changeset = Changeset.validate_length(changeset, "title", %{"min" => 3, "max" => 200})
    changeset = Changeset.validate_length(changeset, "description", %{"max" => 1000})
    priority_values = [ChangesetValue.string_value("low"), ChangesetValue.string_value("medium"), ChangesetValue.string_value("high")]
    changeset = Changeset.validate_inclusion(changeset, "priority", priority_values)
    changeset = Changeset.foreign_key_constraint(changeset, "user_id")
    changeset
  end

  @doc "Function toggle_completed"
  @spec toggle_completed(Todo.t()) :: Ecto.Changeset.t()
  def toggle_completed(todo) do
    (
          params = Haxe.Ds.StringMap.new()
          value = ChangesetValue.bool_value(not todo.completed)
          params.set("completed", value)
          Todo.changeset(todo, params)
        )
  end

  @doc "Function update_priority"
  @spec update_priority(Todo.t(), String.t()) :: Ecto.Changeset.t()
  def update_priority(todo, priority) do
    (
          params = Haxe.Ds.StringMap.new()
          value = ChangesetValue.string_value(priority)
          params.set("priority", value)
          Todo.changeset(todo, params)
        )
  end

  @doc "Function add_tag"
  @spec add_tag(Todo.t(), String.t()) :: Ecto.Changeset.t()
  def add_tag(todo, tag) do
    temp_array = nil
    if ((todo.tags != nil)) do
          temp_array = todo.tags
        else
          temp_array = []
        end
    temp_array ++ [tag]
    params = Haxe.Ds.StringMap.new()
    g_array = []
    g_counter = 0
    Enum.map(temp_array, fn v -> ChangesetValue.string_value(v) end)
    value = ChangesetValue.array_value(g_counter)
    params.set("tags", value)
    Todo.changeset(todo, params)
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
