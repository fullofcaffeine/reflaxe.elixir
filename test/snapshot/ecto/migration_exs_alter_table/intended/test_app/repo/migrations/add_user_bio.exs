defmodule TestApp.Repo.Migrations.AddUserBio do
  use Ecto.Migration
  def up() do
    alter table(:users) do
      add(:bio, :text)
    end
  end
  def down() do
    alter table(:users) do
      remove(:bio)
    end
  end
end
