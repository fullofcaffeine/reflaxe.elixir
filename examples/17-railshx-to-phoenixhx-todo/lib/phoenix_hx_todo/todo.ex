defmodule PhoenixHxTodo.Todo do
  use Ecto.Schema
  schema "todos" do
    _ = field(:title, :string)
    _ = field(:notes, :string)
    _ = field(:completed, :boolean)
    _ = field(:user_id, :integer)
    _ = timestamps()
  end
  def new() do
    struct = %{:__reflaxe_class__ => PhoenixHxTodo.Todo, :id => nil, :title => nil, :notes => nil, :completed => nil, :user_id => nil}
    struct = %{struct | completed: false}
    struct = %{struct | completed: false}
    struct
  end
  def toggle_completed(todo) do
    params = %{completed: not todo.completed}
    Ecto.Changeset.change(todo, params)
  end

  def changeset(todo, attrs) do
    todo
    |> Ecto.Changeset.cast(attrs, [:title, :notes, :completed, :user_id])
    |> Ecto.Changeset.validate_required([:title, :user_id])
  end
end
