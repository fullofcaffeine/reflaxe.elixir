package controllers;

/**
 * Phoenix controller with @:route annotations
 * Demonstrates RESTful route generation and parameter handling
 */
@:controller
class UserController {
    
    @:route({method: "GET", path: "/users"})
    public function index(): String {
        return "List all users";
    }
    
    @:route({method: "GET", path: "/users/:id"})
    public function show(id: Int): String {
        return "Show user " + id;
    }
    
    @:route({method: "POST", path: "/users"})
    public function create(user: Dynamic): String {
        return "Create new user";
    }
    
    @:route({method: "PUT", path: "/users/:id"})
    public function update(id: Int, user: Dynamic): String {
        return "Update user " + id;
    }
    
    @:route({method: "DELETE", path: "/users/:id"})
    public function delete(id: Int): String {
        return "Delete user " + id;
    }
    
    public static function main() {
        trace("Phoenix Router DSL Example - User Controller");
    }
}