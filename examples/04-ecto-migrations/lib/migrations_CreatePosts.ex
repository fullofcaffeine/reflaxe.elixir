defmodule Repo.Migrations.CreatePosts do
  @moduledoc """
  Generated migration for default_table table
  
  Creates default_table table with proper schema and indexes
  following Ecto migration patterns with compile-time validation.
  """
  
  use Ecto.Migration
  
  @doc """
  Run the migration - creates default_table table
  """
  def change do
    create table(:default_table) do

      timestamps()
    end
    
    create unique_index(:default_table, [:email])
  end
  
  @doc """
  Rollback migration - drops default_table table
  """
  def down do
    drop table(:default_table)
  end
end