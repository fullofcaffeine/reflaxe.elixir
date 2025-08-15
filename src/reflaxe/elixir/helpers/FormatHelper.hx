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
     * Clean JavaDoc-style comments to plain text suitable for Elixir
     * @param docString The JavaDoc documentation to clean
     * @return Cleaned documentation text
     */
    public static function cleanJavaDoc(docString: String): String {
        if (docString == null || docString == "") {
            return "";
        }
        
        // Remove JavaDoc asterisks and clean up indentation
        var lines = docString.split("\n");
        var cleanedLines = [];
        var wasMultiLine = lines.length > 1;
        
        for (line in lines) {
            // Replace tabs with spaces (2 spaces per tab for Elixir convention)
            // Use regex for robust tab replacement
            var tabRegex = ~/\t/g;
            line = tabRegex.replace(line, "  ");
            
            var trimmed = line.trim();
            
            // Skip empty lines that are just asterisks
            if (trimmed == "*" || trimmed == "") {
                if (cleanedLines.length > 0 && cleanedLines[cleanedLines.length - 1] != "") {
                    cleanedLines.push("");
                }
                continue;
            }
            
            // Remove leading asterisk and whitespace
            if (trimmed.startsWith("* ")) {
                cleanedLines.push(trimmed.substr(2));
            } else if (trimmed.startsWith("*")) {
                cleanedLines.push(trimmed.substr(1));
            } else {
                cleanedLines.push(trimmed);
            }
        }
        
        // Remove trailing empty lines
        while (cleanedLines.length > 0 && cleanedLines[cleanedLines.length - 1] == "") {
            cleanedLines.pop();
        }
        
        var result = cleanedLines.join("\n");
        
        // If original was multi-line but we collapsed it to single line, 
        // preserve multi-line format for proper documentation formatting
        if (wasMultiLine && !result.contains("\n") && result.length > 0) {
            // Add a single newline to ensure multi-line formatting is used
            result = result + "\n";
        }
        
        return result;
    }
    
    /**
     * Format Elixir documentation string
     * @param docString The documentation content
     * @param isModuleDoc Whether this is @moduledoc (vs @doc)
     * @param indentLevel Base indentation level
     * @return Formatted documentation
     */
    public static function formatDoc(docString: String, isModuleDoc: Bool = false, indentLevel: Int = 1): String {
        
        if (docString == null || docString == "") {
            return "";
        }
        
        // Clean JavaDoc-style formatting first
        var cleanDoc = cleanJavaDoc(docString);
        
        if (cleanDoc == "") {
            return "";
        }
        
        // Ensure any remaining tabs are converted to spaces using multiple approaches
        cleanDoc = StringTools.replace(cleanDoc, "\t", "  ");
        var tabRegex = ~/\t/g;
        cleanDoc = tabRegex.replace(cleanDoc, "  ");
        
        
        var docType = isModuleDoc ? "@moduledoc" : "@doc";
        var baseIndent = indent("", indentLevel);
        
        if (cleanDoc.contains("\n")) {
            // Multi-line documentation - always use heredoc for proper formatting
            var lines = cleanDoc.split("\n");
            var formattedLines = lines.map(line -> {
                if (line == "") return "";
                // Replace any remaining tabs in individual lines
                var tabRegex = ~/\t/g;
                line = tabRegex.replace(line, "  ");
                return baseIndent + "  " + line;
            });
            return baseIndent + docType + ' """\n' + formattedLines.join("\n") + '\n' + baseIndent + '"""';
        } else {
            // Single-line documentation - escape quotes and backslashes
            var escapedDoc = cleanDoc.split('"').join('\\"').split('\\').join('\\\\');
            return baseIndent + docType + ' "' + escapedDoc + '"';
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