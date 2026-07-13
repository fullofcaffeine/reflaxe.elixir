defmodule HandwrittenCorpus.TodoApp.Todo do
  use Ecto.Schema

  schema "todos" do
    field(:title, :string)
    field(:description, :string)
    field(:completed, :boolean, default: false)
    field(:priority, :string, default: "medium")
    field(:due_date, :naive_datetime)
    field(:tags, {:array, :string})
    field(:user_id, :integer)
    field(:organization_id, :integer)
    timestamps()
  end

  def toggle_completed(todo), do: Ecto.Changeset.change(todo, completed: !todo.completed)
  def update_priority(todo, priority), do: Ecto.Changeset.change(todo, priority: priority)

  def changeset(todo, attrs) do
    todo
    |> Ecto.Changeset.cast(attrs, [
      :title,
      :description,
      :completed,
      :priority,
      :due_date,
      :tags,
      :user_id,
      :organization_id
    ])
    |> Ecto.Changeset.validate_required([:title])
  end
end
