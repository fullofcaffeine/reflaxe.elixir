defmodule CreateTodos do
  use Ecto.Migration

  def up do
    create table(:todos) do
      timestamps()
    end
  end

  def down do
    drop table(:todos)
  end

  @doc "Generated from Haxe migrateAddIndexes"
  def migrate_add_indexes() do
    nil
  end


  @doc "Generated from Haxe rollbackCustomOperation"
  def rollback_custom_operation() do
    nil
  end


end
