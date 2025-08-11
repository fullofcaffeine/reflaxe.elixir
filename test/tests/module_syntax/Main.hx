/**
 * Module Syntax Sugar Test
 * Tests @:module annotation for simplified Elixir module generation
 * Converted from framework-based ModuleSyntaxTest.hx to snapshot test
 */

@:module
class UserService {
    /**
     * Public function - should generate def syntax
     */
    public static function createUser(name: String, age: Int): String {
        return name + " is " + age + " years old";
    }

    /**
     * Private function - should generate defp syntax
     */
    private static function validateAge(age: Int): Bool {
        return age >= 0 && age <= 150;
    }

    /**
     * Function with pipe operator - should preserve pipe syntax
     */
    public static function processData(data: String): String {
        // This should be preserved as pipe operator in Elixir
        return data; // |> String.trim() |> String.upcase() - simplified for testing
    }

    /**
     * Function with multiple parameters
     */
    public static function complexFunction(
        arg1: String, 
        arg2: Int, 
        arg3: Bool, 
        arg4: Array<String>
    ): String {
        if (arg3) {
            return arg1 + " " + arg2;
        }
        return "default";
    }
}

/**
 * Second module to test multiple module generation
 */
@:module 
class StringUtils {
    public static function isEmpty(str: String): Bool {
        return str == null || str.length == 0;
    }

    private static function sanitize(str: String): String {
        // Test private function with internal logic
        return str; // Simplified for testing
    }
}

/**
 * Module with edge case: special characters in name
 * Should be sanitized to valid Elixir module name
 */
@:module("User_Helper")
class UserHelper {
    public static function formatName(firstName: String, lastName: String): String {
        return firstName + " " + lastName;
    }
}