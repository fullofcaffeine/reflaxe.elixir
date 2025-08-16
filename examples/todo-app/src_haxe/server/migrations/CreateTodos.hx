package server.migrations;

/**
 * Generated Haxe migration: CreateTodos
 * 
 * This migration will create/modify the todos table.
 * Customize the fields and operations below, then run `mix compile` 
 * to generate the corresponding Elixir migration.
 */
@:migration({table: "todos"})
@:timestamps
class CreateTodos {
  
  public var title: String;
  public var description: String;
  public var completed: Bool;
  public var priority: String;
  public var due_date: Dynamic;
  public var tags: Dynamic;
  public var user_id: Int;
  
  /**
   * Custom migration operations
   * Functions starting with 'migrate' will be included in the migration
   */
  public function migrateAddIndexes(): Void {
    // Add indexes for better query performance
    // Note: This would need proper migration DSL support
    // For now, indexes are added in the generated Elixir file
  }
  
  /**
   * Rollback operations  
   * Functions starting with 'rollback' will be included in the down function
   */
  public function rollbackCustomOperation(): Void {
    // Add any custom rollback logic here
  }
}
