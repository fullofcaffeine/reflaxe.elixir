package;

import ecto.TypedQuery;
import ecto.SortDirection;

/**
 * Test that invalid string literals for SortDirection cause compile-time errors
 * 
 * This test validates that the enum abstract pattern provides compile-time
 * type safety for string literals.
 */
class Main {
    public static function main() {
        testValidStringLiterals();
        testEnumValues();
        
        // NOTE: The following would cause COMPILE-TIME ERRORS:
        // testInvalidStringLiterals();  // Uncomment to verify compile error
    }
    
    static function testValidStringLiterals() {
        // These should compile successfully with string literals
        var dir1: SortDirection = "asc";   // ✅ Valid string literal
        var dir2: SortDirection = "desc";  // ✅ Valid string literal
        
        trace("Valid string literals compiled successfully");
    }
    
    static function testEnumValues() {
        // These should compile successfully with enum values
        var dir1: SortDirection = Asc;              // ✅ Enum value
        var dir2: SortDirection = SortDirection.Desc; // ✅ Fully qualified
        
        trace("Enum values compiled successfully");
    }
    
    // IMPORTANT: This function intentionally contains code that SHOULD NOT compile
    // Uncomment to verify that invalid strings cause compile-time errors
    /*
    static function testInvalidStringLiterals() {
        // These MUST cause compile-time errors:
        var dir1: SortDirection = "DeSCo";     // ❌ Invalid case
        var dir2: SortDirection = "ascending"; // ❌ Wrong value
        var dir3: SortDirection = "up";        // ❌ Not a valid option
        var dir4: SortDirection = "";          // ❌ Empty string
        
        trace("This should never execute - compile error expected!");
    }
    */
    
    // Test in actual query context
    static function testInQuery() {
        var query = TypedQuery.from(User)
            .orderBy(u -> [{field: u.name, direction: "asc"}])   // ✅ Valid
            .orderBy(u -> [{field: u.email, direction: Desc}]);  // ✅ Valid
            
        // This would fail at compile time:
        // .orderBy(u -> [{field: u.id, direction: "DeSCo"}]); // ❌ Compile error
        
        trace("Query with typed string literals compiled successfully");
    }
}

// Test schema
@:schema
class User {
    public var id: Int;
    public var name: String;
    public var email: String;
    
    public function new() {}
}