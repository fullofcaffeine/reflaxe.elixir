package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.NamingHelper;

/**
 * MapCompiler - Transforms Haxe Map operations to idiomatic Elixir patterns
 * 
 * This compiler helper handles the transformation of OOP-style Haxe Map code
 * into functional Elixir Map operations. Instead of generating method calls
 * like map.set(key, value), it produces idiomatic Elixir like Map.put(map, key, value).
 */
class MapCompiler {
    
    /**
     * Transform Map constructor calls to appropriate Elixir patterns
     * @param className The original Haxe class name (e.g., "Map", "haxe.ds.StringMap")
     * @param args Constructor arguments
     * @return Idiomatic Elixir map creation
     */
    public static function compileMapConstructor(className: String, args: Array<String>): String {
        // All Haxe Map types become Elixir's built-in map literals
        return switch (className) {
            case "Map" | "haxe.ds.StringMap" | "haxe.ds.IntMap" | "haxe.ds.ObjectMap" | 
                 "haxe.ds.EnumValueMap" | "Haxe.Ds.StringMap" | "Haxe.Ds.IntMap" | "Haxe.Ds.ObjectMap":
                if (args.length > 0) {
                    // new Map(initialData) → Map.new(initialData)
                    'Map.new(${args.join(", ")})';
                } else {
                    // new Map() → %{}
                    '%{}';
                }
            case _:
                // For unknown map types, fall back to constructor call
                '${className}.new(${args.join(", ")})';
        }
    }
    
    /**
     * Transform Map method calls to idiomatic Elixir Map module functions
     * @param mapExpr The map expression (e.g., "my_map")
     * @param methodName The method name (e.g., "set", "get", "remove")
     * @param args The method arguments
     * @return Idiomatic Elixir Map operation
     */
    public static function compileMapMethod(mapExpr: String, methodName: String, args: Array<String>): String {
        return switch (methodName) {
            case "set":
                // map.set(key, value) → Map.put(map, key, value)
                if (args.length >= 2) {
                    'Map.put(${mapExpr}, ${args[0]}, ${args[1]})';
                } else {
                    '${mapExpr}.set(${args.join(", ")})'; // Fallback for malformed calls
                }
                
            case "get":
                // map.get(key) → Map.get(map, key)
                if (args.length >= 1) {
                    'Map.get(${mapExpr}, ${args[0]})';
                } else {
                    '${mapExpr}.get(${args.join(", ")})'; // Fallback
                }
                
            case "exists":
                // map.exists(key) → Map.has_key?(map, key)
                if (args.length >= 1) {
                    'Map.has_key?(${mapExpr}, ${args[0]})';
                } else {
                    '${mapExpr}.exists(${args.join(", ")})'; // Fallback
                }
                
            case "remove":
                // map.remove(key) → Map.delete(map, key)
                if (args.length >= 1) {
                    'Map.delete(${mapExpr}, ${args[0]})';
                } else {
                    '${mapExpr}.remove(${args.join(", ")})'; // Fallback
                }
                
            case "clear":
                // map.clear() → %{}
                '%{}';
                
            case "keys":
                // map.keys() → Map.keys(map)
                'Map.keys(${mapExpr})';
                
            case "iterator":
                // map.iterator() → Map.values(map) (values iterator)
                'Map.values(${mapExpr})';
                
            case "copy":
                // map.copy() → Map.new(map)
                'Map.new(${mapExpr})';
                
            case "toString":
                // map.toString() → inspect(map)
                'inspect(${mapExpr})';
                
            case "keyValueIterator":
                // map.keyValueIterator() → Map.to_list(map)
                'Map.to_list(${mapExpr})';
                
            case _:
                // For unknown methods, fall back to OOP-style call
                // This allows for custom methods or future extensions
                '${mapExpr}.${methodName}(${args.join(", ")})';
        }
    }
    
    /**
     * Check if a given class name represents a Map type
     * @param className The class name to check
     * @return True if this is a Map type that should be handled by MapCompiler
     */
    public static function isMapType(className: String): Bool {
        return switch (className) {
            case "Map" | "haxe.ds.StringMap" | "haxe.ds.IntMap" | "haxe.ds.ObjectMap" | 
                 "haxe.ds.EnumValueMap" | "Haxe.Ds.StringMap" | "Haxe.Ds.IntMap" | "Haxe.Ds.ObjectMap":
                true;
            case _:
                // Check if className contains common map indicators
                var lowerName = className.toLowerCase();
                lowerName.indexOf("map") >= 0 && 
                (className.indexOf("Ds") >= 0 || className.indexOf("ds") >= 0 || className.indexOf("Map") == 0);
        }
    }
    
    /**
     * Check if a method name is a Map operation that should be transformed
     * @param methodName The method name to check
     * @return True if this method should be handled by MapCompiler
     */
    public static function isMapMethod(methodName: String): Bool {
        return switch (methodName) {
            case "set" | "get" | "exists" | "remove" | "clear" | "keys" | 
                 "copy" | "toString" | "iterator" | "keyValueIterator":
                true;
            case _:
                false;
        }
    }
}

#end