package controllers;

/**
 * Simple controller class for testing RouterBuildMacro validation
 */
class UserController {
    
    public static function index(): String {
        return "User index";
    }
    
    public static function show(): String {
        return "User show";
    }
    
    public static function create(): String {
        return "User create";
    }
    
    public static function update(): String {
        return "User update";
    }
    
    public static function delete(): String {
        return "User delete";
    }
}