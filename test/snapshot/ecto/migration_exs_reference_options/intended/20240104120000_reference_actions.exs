defmodule TestApp.Repo.Migrations.ReferenceActions do
  use Ecto.Migration
  def up() do
    create table(:children) do
      add(:parent_id, references(:parents, [on_delete: :delete_all, on_update: :update_all]), [null: false])
      add(:optional_id, references(:parents, [on_delete: :nilify_all, on_update: :nilify_all]))
      add(:restricted_id, references(:parents, [on_delete: :restrict, on_update: :restrict]))
      add(:unchanged_id, references(:parents, [on_delete: :nothing, on_update: :nothing]))
      add(:default_id, references(:parents))
      add(:counter, :integer, [null: false, default: 0])
    end
    alter table(:children) do
      add(:later_id, references(:parents, [on_delete: :delete_all]))
    end
  end
  def down() do
    drop(constraint(:children, :children_parent_id_fkey))
    alter table(:children) do
      modify(:parent_id, references(:parents, [on_delete: :restrict, on_update: :nothing]))
    end
    drop(table(:children))
  end
end
