package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

using StringTools;

/**
 * FormatHelper - Elixir code formatting and indentation utilities
 * Provides consistent formatting for generated Elixir code
 */
class FormatHelper {
    
    /**
     * Standard indentation (2 spaces per level, Elixir convention)
     */
    public static final INDENT_SIZE: Int = 2;
    
    /**
     * Indent a single line by specified levels
     * @param line The line to indent
     * @param levels Number of indentation levels (default 1)
     * @return Indented line
     */
    public static function indent(line: String, levels: Int = 1): String {
        var spaces = "";
        for (i in 0...(levels * INDENT_SIZE)) {
            spaces += " ";
        }
        return spaces + line;
    }
    
    /**
     * Indent multiple lines by specified levels
     * @param content Multi-line string content
     * @param levels Number of indentation levels (default 1)
     * @return Content with all lines indented
     */
    public static function indentLines(content: String, levels: Int = 1): String {
        var lines = content.split("\n");
        var indentedLines = [];
        
        for (line in lines) {
            if (line.trim().length > 0) {
                indentedLines.push(indent(line, levels));
            } else {
                indentedLines.push(line); // Preserve empty lines
            }
        }
        
        return indentedLines.join("\n");
    }
    
    /**
     * Format a block of code with proper indentation
     * @param content The code block content
     * @param wrapInDo Whether to wrap in do...end block
     * @param levels Base indentation levels
     * @return Formatted code block
     */
    public static function formatBlock(content: String, wrapInDo: Bool = true, levels: Int = 1): String {
        if (content.trim().length == 0) {
            return wrapInDo ? "do\n" + indent("nil", levels) + "\nend" : "nil";
        }
        
        var indentedContent = indentLines(content, levels);
        
        if (wrapInDo) {
            return "do\n" + indentedContent + "\nend";
        } else {
            return indentedContent;
        }
    }
    
    /**
     * Format function parameters for Elixir
     * @param params Array of parameter strings
     * @param multiline Whether to format as multiline (for many params)
     * @return Formatted parameter list
     */
    public static function formatParams(params: Array<String>, multiline: Bool = false): String {
        if (params.length == 0) {
            return "";
        }
        
        if (multiline && params.length > 3) {
            return "\n" + params.map(p -> indent(p)).join(",\n") + "\n";
        } else {
            return params.join(", ");
        }
    }
    
    /**
     * Format Elixir documentation string
     * @param docString The documentation content
     * @param isModuleDoc Whether this is @moduledoc (vs @doc)
     * @param indentLevel Base indentation level
     * @return Formatted documentation
     */
    public static function formatDoc(docString: String, isModuleDoc: Bool = false, indentLevel: Int = 1): String {
        var docType = isModuleDoc ? "@moduledoc" : "@doc";
        var baseIndent = indent("", indentLevel);
        
        if (docString.contains("\n")) {
            // Multi-line documentation
            var lines = docString.split("\n");
            var formattedLines = lines.map(line -> baseIndent + "  " + line);
            return baseIndent + docType + ' """\n' + formattedLines.join("\n") + '\n' + baseIndent + '"""';
        } else {
            // Single-line documentation
            return baseIndent + docType + ' "${docString}"';
        }
    }
    
    /**
     * Format Elixir type specification
     * @param funcName Function name
     * @param paramTypes Array of parameter type strings
     * @param returnType Return type string
     * @param indentLevel Base indentation level
     * @return Formatted @spec annotation
     */
    public static function formatSpec(funcName: String, paramTypes: Array<String>, returnType: String, indentLevel: Int = 1): String {
        var baseIndent = indent("", indentLevel);
        var paramStr = paramTypes.length > 0 ? paramTypes.join(", ") : "";
        return baseIndent + '@spec ${funcName}(${paramStr}) :: ${returnType}';
    }
}

#end