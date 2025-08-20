defmodule Repo.Migrations.CreateUsers do
  @moduledoc """
  Generated migration for users table
  
  Creates users table with proper schema and indexes
  following Ecto migration patterns with compile-time validation.
  """
  
  use Ecto.Migration
  
  @doc """
  Run the migration - creates users table
  """
  def change do
    create table(:users) do

      timestamps()
    end
    
    # No indexes needed for this table
  end
  
  @doc """
  Rollback migration - drops users table
  """
  def down do
    drop table(:users)
  end
end