defmodule TestApp.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  def up() do
    create table(:users) do
      add(:email, :string, [null: false])
      add(:active, :boolean, [default: true])
      timestamps()
    end
    create(unique_index(:users, [:email]))
  end
  def down() do
    drop(table(:users))
  end
end
