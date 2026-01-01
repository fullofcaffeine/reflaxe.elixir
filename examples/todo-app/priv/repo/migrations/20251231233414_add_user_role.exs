defmodule TodoApp.Repo.Migrations.AddUserRole do
  use Ecto.Migration
  def up() do
    alter table(:users) do
      add(:role, :string, [null: false, default: "user"])
    end
  end
  def down() do
    alter table(:users) do
      remove(:role)
    end
  end
end
