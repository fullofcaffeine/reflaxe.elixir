defmodule TodoApp.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration
  def up() do
    create table(:audit_logs) do
      add(:organization_id, :integer, [null: false])
      add(:actor_id, :integer, [null: false])
      add(:action, :string, [null: false])
      add(:entity, :string, [null: false])
      add(:entity_id, :integer)
      add(:metadata, :map)
      timestamps()
    end
    create(index(:audit_logs, [:organization_id]))
    create(index(:audit_logs, [:actor_id]))
    create(index(:audit_logs, [:action]))
    create(index(:audit_logs, [:entity]))
    create(index(:audit_logs, [:inserted_at]))
  end
  def down() do
    drop(table(:audit_logs))
  end
end
