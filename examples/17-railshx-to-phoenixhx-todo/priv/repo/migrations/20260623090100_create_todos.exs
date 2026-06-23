defmodule PhoenixHxTodo.Repo.Migrations.CreateTodos do
  use Ecto.Migration
  def up() do
    create table(:todos) do
      add(:title, :string, [null: false])
      add(:notes, :text)
      add(:completed, :boolean, [default: false])
      add(:user_id, :integer, [null: false])
      timestamps()
    end
    create(index(:todos, [:user_id]))
    create(index(:todos, [:completed]))
  end
  def down() do
    drop(table(:todos))
  end
end
