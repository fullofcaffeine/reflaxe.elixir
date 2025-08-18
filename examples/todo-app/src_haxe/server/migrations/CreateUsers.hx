package server.migrations;

/**
 * Generated Haxe migration: CreateUsers
 * 
 * This migration creates the users table with authentication fields
 * and proper indexes for performance and security.
 */
@:migration({table: "users"})
@:timestamps
class CreateUsers {
  
  // User identification and profile fields
  @:field({type: "string", null: false})
  public var name: String;
  
  @:field({type: "string", null: false})
  public var email: String;
  
  // Authentication fields
  @:field({type: "string", null: false})
  public var password_hash: String;
  
  // Account status and tracking
  @:field({type: "naive_datetime"})
  public var confirmed_at: Dynamic;
  
  @:field({type: "naive_datetime"})
  public var last_login_at: Dynamic;
  
  @:field({type: "boolean", default: true})
  public var active: Bool;
  
  /**
   * Migration operations for creating indexes and constraints
   */
  public function migrateAddIndexes(): Void {
    // Add unique index on email for authentication
    // Note: In real migration DSL this would be:
    // create unique_index(:users, [:email])
    
    // Add index on active status for efficient filtering
    // create index(:users, [:active])
    
    // Add index on confirmed_at for filtering confirmed users
    // create index(:users, [:confirmed_at])
    
    // Add index on last_login_at for activity tracking
    // create index(:users, [:last_login_at])
  }
  
  /**
   * Add constraints for data integrity
   */
  public function migrateAddConstraints(): Void {
    // Add check constraint for email format
    // Note: In real migration DSL this would be:
    // create constraint(:users, :email_format, check: "email ~ '^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$'")
    
    // Add check constraint for name length
    // create constraint(:users, :name_length, check: "length(name) >= 2")
  }
  
  /**
   * Rollback operations for removing indexes and constraints
   */
  public function rollbackRemoveIndexes(): Void {
    // drop_if_exists index(:users, [:email])
    // drop_if_exists index(:users, [:active])
    // drop_if_exists index(:users, [:confirmed_at])
    // drop_if_exists index(:users, [:last_login_at])
  }
  
  public function rollbackRemoveConstraints(): Void {
    // drop_if_exists constraint(:users, :email_format)
    // drop_if_exists constraint(:users, :name_length)
  }
}