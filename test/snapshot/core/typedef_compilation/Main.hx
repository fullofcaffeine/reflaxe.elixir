/**
 * Typedef Compilation Test
 * Tests compilation of Haxe typedefs to Elixir @type specifications
 */

// Simple type aliases
typedef UserId = Int;
typedef Username = String;
typedef Score = Float;
typedef IsActive = Bool;

// Structural types (anonymous objects)
typedef User = {
    id: UserId,
    name: Username,
    age: Int,
    ?email: String  // Optional field
}

// Nested structural types
typedef Company = {
    name: String,
    employees: Array<User>,
    ?address: Address
}

typedef Address = {
    street: String,
    city: String,
    zipCode: String,
    ?country: String
}

// Function types
typedef Callback = (String, Int) -> Bool;
typedef AsyncHandler = () -> Void;
typedef Processor = (User) -> User;
typedef Validator = (String) -> {valid: Bool, ?error: String};

// Generic types
typedef Result<T> = {
    ok: Bool,
    ?value: T,
    ?error: String
}

typedef Pair<A, B> = {
    first: A,
    second: B
}

typedef Container<T> = {
    items: Array<T>,
    count: Int
}

// Complex nested types
typedef ApiResponse = {
    status: Int,
    data: Result<Array<User>>,
    ?metadata: {
        timestamp: Float,
        version: String
    }
}

// Union-like types using optional fields
typedef Status = {
    ?success: Bool,
    ?error: String,
    ?pending: Bool
}

// Map-based types
typedef Config = {
    settings: Map<String, Dynamic>,
    flags: Array<String>
}

// Recursive type reference
typedef TreeNode = {
    value: Int,
    ?left: TreeNode,
    ?right: TreeNode
}

class Main {
    static function main() {
        // Test simple aliases
        var userId: UserId = 123;
        var username: Username = "john_doe";
        var score: Score = 98.5;
        var isActive: IsActive = true;
        
        // Test structural types
        var user: User = {
            id: userId,
            name: username,
            age: 30,
            email: "john@example.com"
        };
        
        // Test optional fields
        var minimalUser: User = {
            id: 456,
            name: "jane",
            age: 25
            // email is optional, not provided
        };
        
        // Test nested structures
        var company: Company = {
            name: "Tech Corp",
            employees: [user, minimalUser],
            address: {
                street: "123 Main St",
                city: "San Francisco",
                zipCode: "94102",
                country: "USA"
            }
        };
        
        // Test generic types
        var successResult: Result<String> = {
            ok: true,
            value: "Success!"
        };
        
        var errorResult: Result<String> = {
            ok: false,
            error: "Something went wrong"
        };
        
        var pair: Pair<Int, String> = {
            first: 42,
            second: "Answer"
        };
        
        // Test function types (as variables)
        var callback: Callback = function(msg: String, code: Int): Bool {
            return code == 200;
        };
        
        var handler: AsyncHandler = function(): Void {
            trace("Async operation complete");
        };
        
        // Test complex nested type
        var apiResponse: ApiResponse = {
            status: 200,
            data: {
                ok: true,
                value: [user, minimalUser]
            },
            metadata: {
                timestamp: Date.now().getTime(),
                version: "1.0.0"
            }
        };
        
        // Test union-like type
        var successStatus: Status = {
            success: true
        };
        
        var errorStatus: Status = {
            error: "Failed to process"
        };
        
        // Test recursive type
        var tree: TreeNode = {
            value: 10,
            left: {
                value: 5,
                left: {value: 3},
                right: {value: 7}
            },
            right: {
                value: 15
            }
        };
        
        trace("Typedef compilation test complete");
    }
}