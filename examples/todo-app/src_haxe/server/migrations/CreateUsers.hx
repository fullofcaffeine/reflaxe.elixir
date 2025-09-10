package server.migrations;

import ecto.Migration;
import ecto.Migration.*;

/**
 * Migration to create the users table with authentication fields
 * 
 * Uses the new typed Migration DSL for compile-time validation
 * and proper index/constraint generation.
 */
@:migration
class CreateUsers extends Migration {
    
    public function up(): Void {
        createTable("users")
            // User identification and profile fields
            .addColumn("name", String(), {nullable: false})
            .addColumn("email", String(), {nullable: false})
            
            // Authentication fields
            .addColumn("password_hash", String(), {nullable: false})
            .addColumn("confirmed_at", DateTime)
            .addColumn("last_login_at", DateTime)
            .addColumn("active", Boolean, {defaultValue: true})
            
            // Timestamps
            .addTimestamps()
            
            // Indexes for performance
            .addUniqueConstraint(["email"], "users_email_unique")
            .addIndex(["active"])
            .addIndex(["confirmed_at"])
            .addIndex(["last_login_at"])
            
            // Data integrity constraints
            .addCheckConstraint("email_format", "email ~ '^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$'")
            .addCheckConstraint("name_length", "length(name) >= 2");
    }
    
    public function down(): Void {
        dropTable("users");
    }
}