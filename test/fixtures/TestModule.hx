package fixtures;

@:module
class UserService {
    
    /**
     * Create a new user with validation
     */
    public function createUser(name: String, email: String): Dynamic {
        // This should demonstrate pipe operator support
        return name + " <" + email + ">";
    }
    
    /**
     * Private helper function for validation
     */
    @:private
    public function validateUser(userData: Dynamic): Bool {
        return userData != null;
    }
    
    /**
     * Get user by ID with data processing
     */
    public function getUserById(id: Int): Dynamic {
        // This function will demonstrate clean module syntax
        return "User " + id;
    }
}