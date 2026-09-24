defmodule TestApp.Repo.Migrations.CompositeReference do
  use Ecto.Migration
  def up() do
    create table(:scoped_parents) do
      add(:scope_id, :integer, [null: false])
      add(:public_id, :string, [null: false])
    end
    create(unique_index(:scoped_parents, [:scope_id, :public_id]))
    create table(:scoped_children) do
      add(:"scope-tag", :integer, [null: false])
      add(:parent_key, references(:scoped_parents, [type: :string, column: :public_id, name: :scoped_parent_key, with: ["scope-tag": :scope_id], on_delete: :restrict, on_update: :restrict]), [null: false])
      add(:future_key, :string)
    end
    alter table(:scoped_children) do
      add(:backup_key, references(:scoped_parents, [type: :string, column: :public_id, with: ["scope-tag": :scope_id]]), [null: false, default: "shared"])
      modify(:future_key, references(:scoped_parents, [type: :string, column: :public_id, with: ["scope-tag": :scope_id]]))
    end
  end
  def down() do
    drop(table(:scoped_children))
    drop(table(:scoped_parents))
  end
end
