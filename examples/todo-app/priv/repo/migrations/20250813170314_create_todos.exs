defmodule TodoApp.Repo.Migrations.CreateTodos do
  use Ecto.Migration
  def up() do
    create table(:todos) do
      add(:title, :string, [null: false])
      add(:description, :text)
      add(:completed, :boolean, [default: false])
      add(:priority, :string)
      add(:due_date, :naive_datetime)
      add(:tags, :map)
      add(:user_id, :integer)
      timestamps()
    end
    create(index(:todos, [:user_id]))
    create(index(:todos, [:completed]))
  end
  def down() do
    drop(table(:todos))
  end
end
