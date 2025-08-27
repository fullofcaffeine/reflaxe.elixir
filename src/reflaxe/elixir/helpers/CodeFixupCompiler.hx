#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.AnnotationSystem;
import reflaxe.elixir.SourceMapWriter;
using StringTools;

/**
 * CodeFixupCompiler: Centralized post-processing and code cleanup operations
 * 
 * WHY: Post-processing logic was scattered throughout ElixirCompiler creating maintenance debt.
 *      Generated code often needs cleanup to be idiomatic and fix known compilation artifacts.
 *      Separation of concerns: code generation vs post-processing cleanup.
 * WHAT: Provides comprehensive post-processing operations including malformed conditional fixes,
 *       app name resolution and replacement, source map management, and syntax cleanup.
 * HOW: Implements focused cleanup methods that examine generated code strings and AST metadata
 *      to apply targeted fixes and improvements to the final output.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused entirely on post-processing and cleanup operations
 * - Open/Closed Principle: Easy to add new cleanup operations without modifying generation logic
 * - Testability: Cleanup logic can be tested independently from code generation
 * - Maintainability: Clear separation between generation and post-processing concerns
 * - Performance: Optimized cleanup operations with targeted pattern matching
 * 
 * EDGE CASES:
 * - Complex nested patterns requiring multiple cleanup passes
 * - Conflicting cleanup operations that might interfere with each other
 * - Context-sensitive fixes that depend on surrounding code structure
 * - Performance impact of string-based pattern matching on large files
 * - Cleanup operations that might create new syntax errors
 * 
 * @see docs/03-compiler-development/CODE_FIXUP.md - Complete post-processing guide
 */
@:nullSafety(Off)
class CodeFixupCompiler {
    var compiler: ElixirCompiler;
    private var currentSourceMapWriter: Null<SourceMapWriter> = null;

    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }

    /**
     * Fix malformed conditional expressions that can occur in complex Y combinator bodies
     * 
     * WHY: Y combinator compilation can generate malformed else clauses without proper if conditions
     * WHAT: Identifies and comments out problematic else patterns that would cause syntax errors
     * HOW: Line-by-line analysis with regex pattern matching and indentation preservation
     * 
     * Pattern to fix: "}, else: expression" without proper "if condition, do:" prefix
     * These occur when if-else expressions are incorrectly split during compilation
     * 
     * @param code The generated code to fix
     * @return Fixed code with malformed conditionals commented out
     */
    public function fixMalformedConditionals(code: String): String {
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] Fixing malformed conditionals in code (length: ${code.length})');
        #end
        
        // Simple string-based fix for known malformed patterns
        var fixedCode = code;
        
        // Pattern 1: Fix assignment patterns with hanging else clauses like "empty = false, else: _this = struct.buf"
        // Use simple string replacement for reliability
        var lines = fixedCode.split("\n");
        var fixedLines = [];
        var fixCount = 0;
        
        for (line in lines) {
            var wasFixed = false;
            
            // Pattern 1: Check for malformed assignment with else pattern (with comma)
            if (line.contains(", else:") && line.contains(" = ") && !line.contains("if (")) {
                var indent = extractIndentation(line);
                var trimmed = line.substring(indent.length);
                fixedLines.push(indent + "# FIXME: Malformed assignment with else: " + trimmed);
                wasFixed = true;
                fixCount++;
            } 
            // Pattern 2: Check for malformed assignment with else pattern (without comma)
            else if (line.contains("}, else:") && line.contains(" = ") && !line.contains("if (")) {
                var indent = extractIndentation(line);
                var trimmed = line.substring(indent.length);
                fixedLines.push(indent + "# FIXME: Malformed assignment with hanging else: " + trimmed);
                wasFixed = true;
                fixCount++;
            }
            // Pattern 3: Check for assignments ending with just ", else: nil" 
            else if (line.contains(" = ") && line.endsWith(", else: nil") && !line.contains("if (")) {
                var indent = extractIndentation(line);
                var trimmed = line.substring(indent.length);
                fixedLines.push(indent + "# FIXME: Assignment with hanging else nil: " + trimmed);
                wasFixed = true;
                fixCount++;
            }
            // Pattern 4: Check for assignments with ", else: nil" anywhere in the line
            else if (line.contains(" = ") && line.contains(", else: nil") && !line.contains("if (")) {
                var indent = extractIndentation(line);
                var trimmed = line.substring(indent.length);
                fixedLines.push(indent + "# FIXME: Assignment with hanging else nil anywhere: " + trimmed);
                wasFixed = true;
                fixCount++;
            }
            // Pattern 5: Fix expressions ending with "}, else: expression" that are not complete if-statements
            else if (line.contains("}, else:") && !line.contains("if (")) {
                var indent = extractIndentation(line);
                var trimmed = line.substring(indent.length);
                fixedLines.push(indent + "# FIXME: Malformed conditional: " + trimmed);
                wasFixed = true;
                fixCount++;
            } 
            
            if (!wasFixed) {
                fixedLines.push(line);
            }
        }
        
        var result = fixedLines.join("\n");
        
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] Fixed ${fixCount} malformed conditionals');
//         trace('[CodeFixupCompiler] Result length: ${result.length}');
        #end
        
        return result;
    }

    /**
     * Extract leading whitespace indentation from a line
     * 
     * WHY: Indentation must be preserved when commenting out lines
     * WHAT: Extracts leading whitespace to maintain code formatting
     * HOW: Regex pattern matching for whitespace at line start
     * 
     * @param line The line to analyze
     * @return Leading whitespace string
     */
    private function extractIndentation(line: String): String {
        var spaceMatch = ~/^(\s*)/;
        if (spaceMatch.match(line)) {
            return spaceMatch.matched(1);
        }
        return "";
    }

    /**
     * Get current application name from multiple prioritized sources
     * 
     * WHY: Application names are used throughout generated code and must be consistent
     * WHAT: Resolves app name from compiler defines, annotations, global registry, or fallbacks
     * HOW: Prioritized resolution chain with multiple fallback mechanisms
     * 
     * @return The resolved application name
     */
    public function getCurrentAppName(): String {
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] Resolving current app name');
        #end
        
        // Priority 1: Check compiler define (most explicit and single-source-of-truth)
        // IMPORTANT: Use Context.definedValue() in macro context, NOT Compiler.getDefine()
        // Compiler.getDefine() is a macro function meant for regular code generation
        #if app_name
        var defineValue = haxe.macro.Context.definedValue("app_name");
        if (defineValue != null && defineValue.length > 0) {
            #if debug_code_fixup
//             trace('[CodeFixupCompiler] App name from compiler define: ${defineValue}');
            #end
            return defineValue;
        }
        #end
        
        // Priority 2: Check current class annotation
        if (compiler.currentClassType != null) {
            var annotatedName = AnnotationSystem.getAppName(compiler.currentClassType);
            if (annotatedName != null) {
                #if debug_code_fixup
//                 trace('[CodeFixupCompiler] App name from class annotation: ${annotatedName}');
                #end
                return annotatedName;
            }
        }
        
        // Priority 3: Check global registry (if any class had @:appName)
        var globalName = AnnotationSystem.getGlobalAppName();
        if (globalName != null) {
            #if debug_code_fixup
//             trace('[CodeFixupCompiler] App name from global registry: ${globalName}');
            #end
            return globalName;
        }
        
        // Priority 4: Try to infer from class name
        if (compiler.currentClassType != null) {
            var className = compiler.currentClassType.name;
            if (className.endsWith("App")) {
                #if debug_code_fixup
//                 trace('[CodeFixupCompiler] App name inferred from class: ${className}');
                #end
                return className;
            }
        }
        
        // Priority 5: Ultimate fallback
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] App name using fallback: App');
        #end
        return "App";
    }

    /**
     * Replace getAppName() calls with the actual app name from the annotation
     * 
     * WHY: Dynamic app name injection enables reusable code with configurable app names
     * WHAT: Post-processing step that replaces getAppName() calls with string literals
     * HOW: Regex pattern matching and replacement with syntax error prevention
     * 
     * This post-processing step enables dynamic app name injection in generated code
     * 
     * @param code The generated code to process
     * @param classType The class type for app name resolution
     * @return Code with app name calls replaced
     */
    public function replaceAppNameCalls(code: String, classType: ClassType): String {
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] Replacing app name calls in code (length: ${code.length})');
        #end
        
        var appName = AnnotationSystem.getEffectiveAppName(classType);
        
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] Using app name: ${appName}');
        #end
        
        var processedCode = code;
        
        // Replace direct getAppName() calls - these become simple string literals
        processedCode = processedCode.replace('getAppName()', '"${appName}"');
        
        // Replace method calls like MyClass.getAppName() (camelCase version)
        processedCode = ~/([A-Za-z0-9_]+)\.getAppName\(\)/g.replace(processedCode, '"${appName}"');
        
        // Replace method calls like MyClass.get_app_name() (snake_case version)
        processedCode = ~/([A-Za-z0-9_]+)\.get_app_name\(\)/g.replace(processedCode, '"${appName}"');
        
        // Fix any cases where we ended up with Module."AppName" syntax (invalid)
        // This handles cases where method replacement created invalid syntax
        processedCode = ~/([A-Za-z0-9_]+)\."([^"]+)"/g.replace(processedCode, '"$2"');
        
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] App name replacement complete (new length: ${processedCode.length})');
        #end
        
        return processedCode;
    }

    /**
     * Initialize source map writer for debugging and LLM workflows
     * 
     * WHY: Source maps enable debugging and LLM workflow integration
     * WHAT: Sets up source map tracking for the current output file
     * HOW: Creates SourceMapWriter instance and tracks in compiler state
     * 
     * @param outputPath The output file path for source map generation
     */
    public function initSourceMapWriter(outputPath: String): Void {
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] Initializing source map writer for: ${outputPath}');
        #end
        
        // Only create source map writer if enabled via compiler flag
        if (compiler.sourceMapOutputEnabled) {
            currentSourceMapWriter = new SourceMapWriter(outputPath);
            
            // Register with compiler for position tracking during compilation
            compiler.currentSourceMapWriter = currentSourceMapWriter;
            
            // Track for final output generation
            if (compiler.pendingSourceMapWriters != null) {
                compiler.pendingSourceMapWriters.push(currentSourceMapWriter);
            }
            
            #if debug_code_fixup
//             trace('[CodeFixupCompiler] Source map writer created and registered');
            #end
        } else {
            #if debug_code_fixup
//             trace('[CodeFixupCompiler] Source maps disabled, skipping initialization');
            #end
        }
    }

    /**
     * Finalize source map writer and return source map content
     * 
     * WHY: Source maps must be finalized to generate valid mapping files
     * WHAT: Completes source map generation and returns map content
     * HOW: Finalizes SourceMapWriter state and returns serialized content
     * 
     * @return Source map content or null if not enabled
     */
    public function finalizeSourceMapWriter(): Null<String> {
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] Finalizing source map writer');
        #end
        
        if (currentSourceMapWriter != null) {
            // Generate the source map file and get its path
            var mapPath = currentSourceMapWriter.generateSourceMap();
            
            #if debug_code_fixup
//             trace('[CodeFixupCompiler] Source map generated at: ${mapPath}');
//             trace('[CodeFixupCompiler] Debug info: ${currentSourceMapWriter.getDebugInfo()}');
            #end
            
            // Clear the current writer reference
            currentSourceMapWriter = null;
            
            // Return the path to the generated source map file
            return mapPath;
        }
        
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] No source map writer active, returning null');
        #end
        
        return null;
    }

    /**
     * Clean up empty string concatenations and other syntax artifacts
     * 
     * WHY: Code generation can create unnecessary empty string concatenations
     * WHAT: Removes redundant concatenations and cleans up syntax artifacts
     * HOW: Pattern matching and replacement for common cleanup scenarios
     * 
     * @param code The code to clean up
     * @return Cleaned code with artifacts removed
     */
    public function cleanupSyntaxArtifacts(code: String): String {
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] Cleaning up syntax artifacts');
        #end
        
        var cleanedCode = code;
        
        // Clean up any remaining empty string concatenations
        cleanedCode = cleanedCode.replace(' <> ""', '');
        cleanedCode = cleanedCode.replace('"" <> ', '');
        
        // Clean up double concatenations
        cleanedCode = cleanedCode.replace(' <> <> ', ' <> ');
        
        #if debug_code_fixup
//         trace('[CodeFixupCompiler] Syntax cleanup complete');
        #end
        
        return cleanedCode;
    }
}

#end