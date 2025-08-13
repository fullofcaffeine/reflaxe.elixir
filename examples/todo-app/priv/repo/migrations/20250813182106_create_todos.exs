defmodule TodoApp.Repo.Migrations.CreateTodos do
  @moduledoc """
  Generated from Haxe @:migration class: CreateTodos
  
  Creates todos table with Haxe-defined schema.
  This migration was automatically generated from a Haxe source file
  as part of the Reflaxe.Elixir compilation pipeline.
  """
  
  use Ecto.Migration

  @doc """
  Run the migration - creates todos table
  """
  def change do
    create table(:todos) do
      add :title, :string, null: false
      add :description, :text
      add :completed, :boolean, default: false, null: false
      add :priority, :string, default: "medium"
      add :due_date, :date
      add :tags, {:array, :string}, default: []
      add :user_id, :integer
      timestamps()
    end
    
    # Add indexes for better query performance
    create index(:todos, [:user_id])
    create index(:todos, [:completed])
    create index(:todos, [:priority])
    create index(:todos, [:due_date])
  end
  
  @doc """
  Rollback migration - drops todos table  
  """
  def down do
    drop table(:todos)
  end
end
