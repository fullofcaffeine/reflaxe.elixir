defmodule TodoApp.Repo.Migrations.AddTodoOrganizationId do
  use Ecto.Migration
  def up() do
    alter table(:todos) do
      add(:organization_id, :integer, [null: false, default: 0])
    end
  end
  def down() do
    alter table(:todos) do
      remove(:organization_id)
    end
  end
end
