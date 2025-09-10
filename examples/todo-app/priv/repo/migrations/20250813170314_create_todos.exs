defmodule Repo.Migrations.CreateTodos do
  @moduledoc """
  Generated migration for todos table
  
  Creates todos table with proper schema and indexes
  following Ecto migration patterns with compile-time validation.
  """
  
  use Ecto.Migration
  
  @doc """
  Run the migration - creates todos table
  """
  def change do
    create table(:todos) do
      add :title, :string
      add :description, :string
      add :completed, :boolean, default: false
      add :priority, :string
      add :due_date, :naive_datetime
      add :tags, :map
      add :user_id, :integer
      timestamps()
    end
    
    create index(:todos, [:user_id])
    create index(:todos, [:completed])
  end
  
  @doc """
  Rollback migration - drops todos table
  """
  def down do
    drop table(:todos)
  end
end
