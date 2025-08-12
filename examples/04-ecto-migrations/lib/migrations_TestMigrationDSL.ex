defmodule TestMigrationDSL do
  @moduledoc """
  TestMigrationDSL module generated from Haxe
  
  
 * Test for MigrationDSL helper functions to verify proper Ecto DSL generation
 
  """

  # Static functions
  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  Log.trace("Testing MigrationDSL helper functions...", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 10, className: "migrations.TestMigrationDSL", methodName: "main"})
  users_migration = MigrationDSL.create_table("users", fn t -> (
  t.add_column("name", "string", %{null: false})
  t.add_column("email", "string", %{null: false})
  t.add_column("age", "integer")
  t.add_column("active", "boolean", %{default: true})
  t.add_index(["email"], %{unique: true})
  t.add_index(["name", "active"])
) end)
  Log.trace("Users table creation DSL:", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 23, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace(users_migration, %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 24, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace("", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 25, className: "migrations.TestMigrationDSL", methodName: "main"})
  drop_migration = MigrationDSL.drop_table("users")
  Log.trace("Users table drop DSL:", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 29, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace(drop_migration, %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 30, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace("", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 31, className: "migrations.TestMigrationDSL", methodName: "main"})
  posts_migration = MigrationDSL.create_table("posts", fn t -> (
  t.add_column("title", "string", %{null: false})
  t.add_column("content", "text")
  t.add_column("user_id", "integer", %{null: false})
  t.add_foreign_key("user_id", "users", "id")
  t.add_index(["user_id"])
  t.add_check_constraint("length(title) > 0", "title_not_empty")
) end)
  Log.trace("Posts table creation with foreign key DSL:", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 44, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace(posts_migration, %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 45, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace("", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 46, className: "migrations.TestMigrationDSL", methodName: "main"})
  add_column_result = MigrationDSL.add_column("users", "phone", "string", %{null: true})
  Log.trace("Add column DSL:", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 50, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace(add_column_result, %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 51, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace("", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 52, className: "migrations.TestMigrationDSL", methodName: "main"})
  add_index_result = MigrationDSL.add_index("users", ["phone", "active"], %{unique: false})
  Log.trace("Add index DSL:", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 55, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace(add_index_result, %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 56, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace("", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 57, className: "migrations.TestMigrationDSL", methodName: "main"})
  Log.trace("✅ MigrationDSL helper functions test completed successfully!", %{fileName: "src_haxe/migrations/TestMigrationDSL.hx", lineNumber: 59, className: "migrations.TestMigrationDSL", methodName: "main"})
)
  end

end
