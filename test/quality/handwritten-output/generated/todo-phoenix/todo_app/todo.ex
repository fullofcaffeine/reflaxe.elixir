defmodule TodoApp.Todo do
  use Ecto.Schema

  schema "todos" do
    field(:title, :string)
    field(:description, :string)
    field(:completed, :boolean)
    field(:priority, :string)
    field(:due_date, :naive_datetime)
    field(:tags, {:array, :string})
    field(:user_id, :integer)
    field(:organization_id, :integer)
    timestamps()
  end

  def new() do
    struct = %{
      :__reflaxe_class__ => TodoApp.Todo,
      :id => nil,
      :title => nil,
      :description => nil,
      :completed => nil,
      :priority => nil,
      :due_date => nil,
      :tags => nil,
      :user_id => nil,
      :organization_id => nil
    }

    struct = %{struct | priority: "medium"}
    struct = %{struct | completed: false}
    struct = %{struct | completed: false}
    struct = %{struct | priority: "medium"}
    struct
  end

  def toggle_completed(todo) do
    new_completed = not todo.completed
    Ecto.Changeset.change(todo, %{completed: new_completed})
  end

  def update_priority(todo, priority_param) do
    Ecto.Changeset.change(todo, %{priority: priority_param})
  end

  def create_new(title_param, user_id_param \\ nil) do
    %{
      title: title_param,
      description: "",
      completed: false,
      priority: "medium",
      due_date: nil,
      tags: [],
      user_id: user_id_param,
      organization_id: nil
    }
  end

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
