defmodule EctoMigrationsExample.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  def up() do
    create table(:users) do
      add(:name, :string, [null: false])
      add(:email, :string, [null: false])
      add(:age, :integer)
      add(:active, :boolean, [default: true])
      timestamps()
    end
    create(unique_index(:users, [:email]))
    create(index(:users, [:name, :active]))
  end
  def down() do
    drop(table(:users))
  end
end
