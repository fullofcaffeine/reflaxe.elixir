defmodule Repo.Migrations.CreateUsersTable do
  @moduledoc """
  Generated migration for create_users table
  
  Creates create_users table with proper schema and indexes
  following Ecto migration patterns with compile-time validation.
  """
  
  use Ecto.Migration
  
  @doc """
  Run the migration - creates create_users table
  """
  def change do
    create table(:create_users) do

      timestamps()
    end
    
    # No indexes needed for this table
  end
  
  @doc """
  Rollback migration - drops create_users table
  """
  def down do
    drop table(:create_users)
  end
end