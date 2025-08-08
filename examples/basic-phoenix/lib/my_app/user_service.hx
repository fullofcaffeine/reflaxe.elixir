package lib.my_app;

/**
 * Example User Service demonstrating @:module syntax sugar
 * Shows clean Elixir module generation with pipe operators and private functions
 */
@:module
class UserService {
    
    /**
     * Create user with validation pipeline
     * Demonstrates pipe operator usage and clean function definition
     */
    function createUser(name: String, email: String): Dynamic {
        return {name: name, email: email}
               |> validateUserData()
               |> formatUserData()
               |> saveUser();
    }
    
    /**
     * Find users by email pattern
     * Shows how to build search queries with functional composition
     */
    function findByEmailPattern(pattern: String): Array<Dynamic> {
        return pattern
               |> validatePattern()
               |> buildSearchQuery()
               |> executeQuery();
    }
    
    /**
     * Get all active users
     * Simple function demonstrating clean syntax without boilerplate
     */
    function getAllUsers(): Array<Dynamic> {
        return getUsersFromDatabase()
               |> filterActiveUsers()
               |> sortByName();
    }
    
    /**
     * Update user information with validation
     */
    function updateUser(userId: Int, updates: Dynamic): Dynamic {
        return updates
               |> validateUpdates()
               |> mergeWithExistingUser(userId)
               |> saveUser();
    }
    
    // Private functions demonstrate @:private annotation usage
    // These generate defp functions in Elixir
    
    @:private
    function validateUserData(userData: Dynamic): Dynamic {
        // Validate required fields
        if (userData.name == null || userData.name == "") {
            throw "Name is required";
        }
        if (userData.email == null || !isValidEmail(userData.email)) {
            throw "Valid email is required";
        }
        return userData;
    }
    
    @:private
    function formatUserData(userData: Dynamic): Dynamic {
        // Format data for consistency
        userData.name = trimWhitespace(userData.name);
        userData.email = userData.email.toLowerCase();
        return userData;
    }
    
    @:private
    function saveUser(userData: Dynamic): Dynamic {
        // Simulate database save
        userData.id = generateId();
        userData.created_at = getCurrentTimestamp();
        return userData;
    }
    
    @:private
    function validatePattern(pattern: String): String {
        if (pattern == null || pattern.length < 2) {
            throw "Search pattern must be at least 2 characters";
        }
        return pattern;
    }
    
    @:private
    function buildSearchQuery(pattern: String): String {
        return "SELECT * FROM users WHERE email LIKE '%" + pattern + "%'";
    }
    
    @:private
    function executeQuery(query: String): Array<Dynamic> {
        // Simulate database query execution
        return [
            {id: 1, name: "John Doe", email: "john@example.com"},
            {id: 2, name: "Jane Smith", email: "jane@example.com"}
        ];
    }
    
    @:private
    function getUsersFromDatabase(): Array<Dynamic> {
        // Simulate fetching all users
        return [
            {id: 1, name: "John Doe", email: "john@example.com", active: true},
            {id: 2, name: "Jane Smith", email: "jane@example.com", active: true},
            {id: 3, name: "Bob Wilson", email: "bob@example.com", active: false}
        ];
    }
    
    @:private
    function filterActiveUsers(users: Array<Dynamic>): Array<Dynamic> {
        return users.filter(function(user) return user.active == true);
    }
    
    @:private
    function sortByName(users: Array<Dynamic>): Array<Dynamic> {
        users.sort(function(a, b) {
            if (a.name < b.name) return -1;
            if (a.name > b.name) return 1;
            return 0;
        });
        return users;
    }
    
    @:private
    function validateUpdates(updates: Dynamic): Dynamic {
        // Only allow specific fields to be updated
        var allowedFields = ["name", "email"];
        var filteredUpdates = {};
        
        for (field in allowedFields) {
            if (updates[field] != null) {
                filteredUpdates[field] = updates[field];
            }
        }
        
        return filteredUpdates;
    }
    
    @:private
    function mergeWithExistingUser(userId: Int, updates: Dynamic): Dynamic {
        // Simulate fetching existing user and merging updates
        var existingUser = {
            id: userId,
            name: "Existing User",
            email: "existing@example.com"
        };
        
        // Merge updates
        for (field in Reflect.fields(updates)) {
            Reflect.setField(existingUser, field, Reflect.field(updates, field));
        }
        
        return existingUser;
    }
    
    @:private
    function isValidEmail(email: String): Bool {
        return email.indexOf("@") > 0 && email.indexOf(".") > 0;
    }
    
    @:private
    function trimWhitespace(text: String): String {
        // Simple whitespace trimming
        while (text.charAt(0) == " ") {
            text = text.substring(1);
        }
        while (text.charAt(text.length - 1) == " ") {
            text = text.substring(0, text.length - 1);
        }
        return text;
    }
    
    @:private
    function generateId(): Int {
        return Math.floor(Math.random() * 10000);
    }
    
    @:private
    function getCurrentTimestamp(): String {
        return "2023-01-01T00:00:00Z"; // Simplified for example
    }
}