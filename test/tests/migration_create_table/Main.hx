// Test migration DSL compilation for create table operations
// This tests the AST-based MigrationCompiler's ability to generate proper Ecto migrations

@:migration("users")
class CreateUsersTable {
    // Explicit up/down methods using migration DSL
    public function up(): Void {
        createTable("users");
        addColumn("users", "name", "string");
        addColumn("users", "email", "string");
        addColumn("users", "age", "integer");
        addIndex("users", ["email"]);
        timestamps();
    }
    
    public function down(): Void {
        dropTable("users");
    }
    
    // Helper method for testing
    private function createTable(tableName: String): Void {
        // DSL method - will be detected by MigrationCompiler
    }
    
    private function dropTable(tableName: String): Void {
        // DSL method
    }
    
    private function addColumn(table: String, column: String, type: String): Void {
        // DSL method
    }
    
    private function addIndex(table: String, columns: Array<String>): Void {
        // DSL method
    }
    
    private function timestamps(): Void {
        // DSL method
    }
}

// Test migration with metadata-based generation
@:migration("posts")
@:timestamps
class CreatePostsTable {
    @:field({type: "string", isNull: false})
    public var title: String;
    
    @:field({type: "text"})
    public var content: String;
    
    @:field({type: "integer", defaultValue: 0})
    public var viewCount: Int;
    
    @:field({type: "references", refTable: "users"})
    public var userId: Int;
}

// Test complex migration with conditionals
@:migration("products")
class CreateProductsTable {
    public function up(): Void {
        createTable("products");
        addColumn("products", "name", "string");
        addColumn("products", "price", "decimal");
        
        if (shouldAddInventory()) {
            addColumn("products", "inventory_count", "integer");
        }
        
        timestamps();
    }
    
    public function down(): Void {
        dropTable("products");
    }
    
    private function shouldAddInventory(): Bool {
        return true;
    }
    
    private function createTable(tableName: String): Void {}
    private function dropTable(tableName: String): Void {}
    private function addColumn(table: String, column: String, type: String): Void {}
    private function timestamps(): Void {}
}

class Main {
    public static function main() {
        // Entry point - migrations are compiled as modules
        trace("Migration compilation test");
    }
}