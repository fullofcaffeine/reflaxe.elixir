package phoenix_chat_hx.utils;

/**
 * String utility functions
 * Generated example module
 */
@:module
class StringUtils {
    public static function capitalize(str: String): String {
        if (str.length == 0) return str;
        return str.charAt(0).toUpperCase() + str.substr(1).toLowerCase();
    }
    
    public static function reverse(str: String): String {
        var chars = str.split("");
        chars.reverse();
        return chars.join("");
    }
    
    public static function slugify(str: String): String {
        return str.toLowerCase()
                 .split(" ")
                 .join("-")
                 .split("_")
                 .join("-");
    }
}
