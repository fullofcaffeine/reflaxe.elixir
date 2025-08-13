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
      add :completed, :string
      add :priority, :string
      add :due_date, :string
      add :tags, :string
      add :user_id, :string
      timestamps()
    end
    
    create unique_index(:todos, [:email])
  end
  
  @doc """
  Rollback migration - drops todos table
  """
  def down do
    drop table(:todos)
  end
end