defmodule PhoenixHxTodo.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  def up() do
    create table(:users) do
      add(:name, :string, [null: false])
      add(:email, :string, [null: false])
      timestamps()
    end
    create(unique_index(:users, [:email], [name: :phoenix_hx_todo_users_email_unique]))
    create(constraint(:users, :name_length, [check: "length(name) >= 2"]))
  end
  def down() do
    drop(table(:users))
  end
end
