defmodule TodoApp.Repo.Migrations.AddUserOrganizationId do
  use Ecto.Migration
  def up() do
    alter table(:users) do
      add(:organization_id, :integer, [null: false, default: 0])
    end
  end
  def down() do
    alter table(:users) do
      remove(:organization_id)
    end
  end
end
