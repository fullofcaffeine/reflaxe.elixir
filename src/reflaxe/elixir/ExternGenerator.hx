package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
using StringTools;

/**
 * Automatic extern generation from existing Elixir modules
 * Parses @spec annotations and generates type-safe Haxe interfaces
 * Enables seamless interop with existing Phoenix applications
 */
class ExternGenerator {
    
    /**
     * Regular expressions for parsing Elixir code
     */
    static var MODULE_PATTERN = ~/defmodule\s+([A-Za-z0-9_.]+)\s+do/;
    static var SPEC_PATTERN = ~/@spec\s+([a-z_][a-z0-9_]*[?!]?)\((.*?)\)\s*::\s*(.*?)(?:\n|$)/;
    static var FUNCTION_PATTERN = ~/def\s+([a-z_][a-z0-9_]*[?!]?)(?:\((.*?)\))?\s+do/;
    static var DEFSTRUCT_PATTERN = ~/defstruct\s+\[(.*?)\]$/;
    static var TYPE_PATTERN = ~/@type\s+([a-z_][a-z0-9_]*)\s*::\s*(.*?)(?:\n|$)/;
    
    /**
     * Generate externs from an Elixir file
     */
    public static function generateFromFile(elixirPath: String, outputPath: String = null): String {
        if (!FileSystem.exists(elixirPath)) {
            throw 'Elixir file not found: ${elixirPath}';
        }
        
        var content = File.getContent(elixirPath);
        var moduleName = extractModuleName(content);
        
        if (moduleName == null) {
            throw 'No module definition found in ${elixirPath}';
        }
        
        var specs = extractSpecs(content);
        var functions = extractFunctions(content);
        var struct = extractStruct(content);
        var types = extractTypes(content);
        
        var haxeCode = generateHaxeExtern(moduleName, specs, functions, struct, types);
        
        if (outputPath != null) {
            FileSystem.createDirectory(Path.directory(outputPath));
            File.saveContent(outputPath, haxeCode);
        }
        
        return haxeCode;
    }
    
    /**
     * Generate externs from a directory of Elixir files
     */
    public static function generateFromDirectory(elixirDir: String, outputDir: String): Array<String> {
        if (!FileSystem.exists(elixirDir)) {
            throw 'Directory not found: ${elixirDir}';
        }
        
        var generated = [];
        
        for (file in FileSystem.readDirectory(elixirDir)) {
            if (file.endsWith(".ex") || file.endsWith(".exs")) {
                var inputPath = Path.join([elixirDir, file]);
                var outputFile = file.replace(".ex", ".hx").replace(".exs", ".hx");
                var outputPath = Path.join([outputDir, outputFile]);
                
                try {
                    generateFromFile(inputPath, outputPath);
                    generated.push(outputPath);
                } catch (e: Dynamic) {
                    trace('Warning: Failed to generate extern for ${inputPath}: ${e}');
                }
            }
        }
        
        return generated;
    }
    
    /**
     * Extract module name from Elixir code
     */
    static function extractModuleName(content: String): String {
        if (MODULE_PATTERN.match(content)) {
            return MODULE_PATTERN.matched(1);
        }
        return null;
    }
    
    /**
     * Extract @spec annotations
     */
    static function extractSpecs(content: String): Map<String, {params: Array<String>, returnType: String}> {
        var specs = new Map<String, {params: Array<String>, returnType: String}>();
        
        var lines = content.split("\n");
        for (i in 0...lines.length) {
            var line = lines[i];
            
            // Handle multi-line specs
            if (line.contains("@spec") && !line.contains("::")) {
                var j = i + 1;
                while (j < lines.length && !lines[j].contains("::")) {
                    line += " " + lines[j].trim();
                    j++;
                }
                if (j < lines.length) {
                    line += " " + lines[j];
                }
            }
            
            if (SPEC_PATTERN.match(line)) {
                var funcName = SPEC_PATTERN.matched(1);
                var params = SPEC_PATTERN.matched(2);
                var returnType = SPEC_PATTERN.matched(3);
                
                var paramTypes = parseParamTypes(params);
                specs.set(funcName, {
                    params: paramTypes,
                    returnType: convertElixirType(returnType.trim())
                });
            }
        }
        
        return specs;
    }
    
    /**
     * Extract function definitions
     */
    static function extractFunctions(content: String): Array<{name: String, arity: Int}> {
        var functions = [];
        var seen = new Map<String, Bool>();
        
        for (line in content.split("\n")) {
            if (FUNCTION_PATTERN.match(line)) {
                var funcName = FUNCTION_PATTERN.matched(1);
                var params = FUNCTION_PATTERN.matched(2);
                
                var arity = 0;
                if (params != null && params.trim().length > 0) {
                    arity = params.split(",").length;
                }
                
                var key = '${funcName}/${arity}';
                
                if (!seen.exists(key)) {
                    functions.push({name: funcName, arity: arity});
                    seen.set(key, true);
                }
            }
        }
        
        return functions;
    }
    
    /**
     * Extract defstruct definition
     */
    static function extractStruct(content: String): Array<{field: String, defaultValue: String}> {
        for (line in content.split("\n")) {
            if (DEFSTRUCT_PATTERN.match(line)) {
                var fields = DEFSTRUCT_PATTERN.matched(1);
                var result = [];
                
                // Split by commas, but handle nested structures
                var fieldParts = [];
                var current = "";
                var depth = 0;
                
                for (i in 0...fields.length) {
                    var char = fields.charAt(i);
                    if (char == "," && depth == 0) {
                        fieldParts.push(current.trim());
                        current = "";
                    } else {
                        if (char == "[" || char == "{" || char == "(") depth++;
                        if (char == "]" || char == "}" || char == ")") depth--;
                        current += char;
                    }
                }
                if (current.trim().length > 0) {
                    fieldParts.push(current.trim());
                }
                
                for (field in fieldParts) {
                    field = field.trim();
                    if (field.contains(":") && !field.startsWith(":")) {
                        // Key-value pair like "active: true"
                        var parts = field.split(":");
                        if (parts.length >= 2) {
                            var fieldName = parts[0].trim();
                            var defaultValue = parts[1].trim();
                            result.push({field: fieldName, defaultValue: defaultValue});
                        }
                    } else if (field.startsWith(":")) {
                        // Simple atom like ":name"
                        var fieldName = field.substring(1);
                        result.push({field: fieldName, defaultValue: "nil"});
                    } else if (field.length > 0) {
                        // Simple field
                        result.push({field: field, defaultValue: "nil"});
                    }
                }
                
                return result;
            }
        }
        
        return null;
    }
    
    /**
     * Extract @type definitions
     */
    static function extractTypes(content: String): Map<String, String> {
        var types = new Map<String, String>();
        
        for (line in content.split("\n")) {
            if (TYPE_PATTERN.match(line)) {
                var typeName = TYPE_PATTERN.matched(1);
                var typeDefinition = TYPE_PATTERN.matched(2);
                types.set(typeName, convertElixirType(typeDefinition));
            }
        }
        
        return types;
    }
    
    /**
     * Parse parameter types from @spec
     */
    static function parseParamTypes(params: String): Array<String> {
        if (params.trim().length == 0) {
            return [];
        }
        
        var result = [];
        var depth = 0;
        var current = "";
        
        for (i in 0...params.length) {
            var char = params.charAt(i);
            
            if (char == "(" || char == "[" || char == "{" || char == "%") {
                depth++;
                current += char;
            } else if (char == ")" || char == "]" || char == "}") {
                depth--;
                current += char;
            } else if (char == "," && depth == 0) {
                result.push(convertElixirType(current.trim()));
                current = "";
            } else {
                current += char;
            }
        }
        
        if (current.trim().length > 0) {
            result.push(convertElixirType(current.trim()));
        }
        
        return result;
    }
    
    /**
     * Convert Elixir type to Haxe type
     */
    static function convertElixirType(elixirType: String): String {
        elixirType = elixirType.trim();
        
        // Handle when clause (for pattern matching types)
        if (elixirType.contains(" when ")) {
            elixirType = elixirType.split(" when ")[0].trim();
        }
        
        // Basic type mappings
        var typeMap = [
            "integer()" => "Int",
            "integer" => "Int",
            "float()" => "Float",
            "float" => "Float",
            "number()" => "Float",
            "number" => "Float",
            "String.t()" => "String",
            "String.t" => "String",
            "binary()" => "String",
            "binary" => "String",
            "atom()" => "String",
            "atom" => "String",
            "boolean()" => "Bool",
            "boolean" => "Bool",
            "any()" => "Dynamic",
            "any" => "Dynamic",
            "term()" => "Dynamic",
            "term" => "Dynamic",
            "nil" => "Null<Dynamic>",
            "pid()" => "Dynamic",
            "pid" => "Dynamic",
            "reference()" => "Dynamic",
            "reference" => "Dynamic"
        ];
        
        for (elixir => haxe in typeMap) {
            if (elixirType == elixir) {
                return haxe;
            }
        }
        
        // Handle list types
        if (elixirType.startsWith("list(") || elixirType.startsWith("[")) {
            if (elixirType.startsWith("list(")) {
                var inner = elixirType.substring(5, elixirType.length - 1);
                return 'Array<${convertElixirType(inner)}>';
            } else if (elixirType == "[]") {
                return "Array<Dynamic>";
            } else if (elixirType.startsWith("[") && elixirType.endsWith("]")) {
                var inner = elixirType.substring(1, elixirType.length - 1);
                return 'Array<${convertElixirType(inner)}>';
            }
        }
        
        // Handle map types
        if (elixirType.startsWith("%{") && elixirType.endsWith("}")) {
            var inner = elixirType.substring(2, elixirType.length - 1);
            if (inner.contains("=>")) {
                var parts = inner.split("=>");
                if (parts.length == 2) {
                    var keyType = convertElixirType(parts[0].trim());
                    var valueType = convertElixirType(parts[1].trim());
                    return 'Map<${keyType}, ${valueType}>';
                }
            }
            return "Dynamic"; // Struct or complex map
        }
        
        // Handle tuple types
        if (elixirType.startsWith("{") && elixirType.endsWith("}")) {
            var inner = elixirType.substring(1, elixirType.length - 1);
            var types = inner.split(",").map(t -> convertElixirType(t.trim()));
            if (types.length == 2) {
                return 'Tuple2<${types[0]}, ${types[1]}>';
            } else if (types.length == 3) {
                return 'Tuple3<${types[0]}, ${types[1]}, ${types[2]}>';
            }
            return "Dynamic"; // Larger tuples
        }
        
        // Handle union types (|)
        if (elixirType.contains("|")) {
            var types = elixirType.split("|").map(t -> t.trim());
            // Check for nil union (nullable)
            if (types.contains("nil")) {
                types.remove("nil");
                if (types.length == 1) {
                    return 'Null<${convertElixirType(types[0])}>';
                }
            }
            // For other unions, use Dynamic
            return "Dynamic";
        }
        
        // Handle keyword lists
        if (elixirType.startsWith("keyword(")) {
            return "Array<Dynamic>";
        }
        
        // Handle specific atoms
        if (elixirType.startsWith(":")) {
            return "String"; // Atoms become strings
        }
        
        // Module types (capitalized)
        if (~/^[A-Z]/.match(elixirType)) {
            // Phoenix/Ecto specific mappings
            if (elixirType.startsWith("Ecto.Changeset")) return "Dynamic";
            if (elixirType.startsWith("Ecto.Query")) return "Dynamic";
            if (elixirType.startsWith("Phoenix.")) return "Dynamic";
            
            // Convert module name to Haxe style
            return elixirType.replace(".", "_");
        }
        
        // Default: keep as-is or return Dynamic
        return "Dynamic";
    }
    
    /**
     * Generate Haxe extern class
     */
    static function generateHaxeExtern(
        moduleName: String,
        specs: Map<String, {params: Array<String>, returnType: String}>,
        functions: Array<{name: String, arity: Int}>,
        struct: Array<{field: String, defaultValue: String}>,
        types: Map<String, String>
    ): String {
        var className = moduleNameToClassName(moduleName);
        var packageName = moduleNameToPackage(moduleName);
        
        var code = new StringBuf();
        
        // Package declaration
        if (packageName != null) {
            code.add('package ${packageName};\n\n');
        }
        
        // Imports
        code.add('#if (elixir || reflaxe_runtime)\n\n');
        
        // Type definitions
        if (types.keys().hasNext()) {
            code.add('// Type definitions\n');
            for (typeName in types.keys()) {
                var haxeType = types.get(typeName);
                code.add('typedef ${capitalize(typeName)} = ${haxeType};\n');
            }
            code.add('\n');
        }
        
        // Struct typedef if present
        if (struct != null) {
            code.add('typedef ${className}Struct = {\n');
            for (field in struct) {
                var fieldName = field.field.startsWith(":") ? 
                    field.field.substring(1) : field.field;
                if (fieldName.trim().length > 0) {
                    code.add('    ?${fieldName}: Dynamic,\n');
                }
            }
            code.add('}\n\n');
        }
        
        // Extern class
        code.add('@:native("${moduleName}")\n');
        code.add('extern class ${className} {\n');
        
        // Generate functions
        for (func in functions) {
            var spec = specs.get(func.name);
            
            if (spec != null) {
                // Use spec types
                code.add('    @:native("${func.name}")\n');
                code.add('    static function ${sanitizeFunctionName(func.name)}(');
                
                for (i in 0...spec.params.length) {
                    if (i > 0) code.add(', ');
                    code.add('arg${i}: ${spec.params[i]}');
                }
                
                code.add('): ${spec.returnType};\n\n');
            } else {
                // No spec, use Dynamic
                code.add('    @:native("${func.name}")\n');
                code.add('    static function ${sanitizeFunctionName(func.name)}(');
                
                for (i in 0...func.arity) {
                    if (i > 0) code.add(', ');
                    code.add('arg${i}: Dynamic');
                }
                
                code.add('): Dynamic;\n\n');
            }
        }
        
        code.add('}\n\n');
        code.add('#end\n');
        
        return code.toString();
    }
    
    /**
     * Convert Elixir module name to Haxe class name
     */
    static function moduleNameToClassName(moduleName: String): String {
        var parts = moduleName.split(".");
        return parts[parts.length - 1];
    }
    
    /**
     * Convert Elixir module name to Haxe package
     */
    static function moduleNameToPackage(moduleName: String): String {
        var parts = moduleName.split(".");
        if (parts.length <= 1) {
            return null;
        }
        
        parts.pop(); // Remove class name
        return parts.join(".").toLowerCase();
    }
    
    /**
     * Sanitize function names for Haxe
     */
    static function sanitizeFunctionName(name: String): String {
        // Remove trailing ? or !
        if (name.endsWith("?")) {
            var baseName = name.substring(0, name.length - 1);
            // If function already starts with "is_", just convert to camelCase
            if (baseName.startsWith("is_")) {
                return "is" + capitalize(baseName.substring(3));
            } else {
                return "is" + capitalize(baseName);
            }
        }
        if (name.endsWith("!")) {
            return name.substring(0, name.length - 1) + "Unsafe";
        }
        return name;
    }
    
    /**
     * Capitalize first letter
     */
    static function capitalize(str: String): String {
        if (str.length == 0) return str;
        return str.charAt(0).toUpperCase() + str.substring(1);
    }
}

// Helper tuple types
typedef Tuple2<T1, T2> = {t1: T1, t2: T2};
typedef Tuple3<T1, T2, T3> = {t1: T1, t2: T2, t3: T3};

#end