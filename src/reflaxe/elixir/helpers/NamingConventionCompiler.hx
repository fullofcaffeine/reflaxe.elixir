#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;

/**
 * NamingConventionCompiler: Centralized naming rule management for Elixir code generation
 * 
 * WHY: Consistent file and module naming is critical for Elixir projects.
 *      Scattered naming logic leads to inconsistencies and maintenance issues.
 * WHAT: Consolidates all naming convention logic - snake_case conversion,
 *       path generation, framework-aware output placement, and universal naming rules.
 * HOW: Delegates to NamingHelper and PhoenixPathGenerator for actual transformations,
 *      provides unified interface for all naming operations in the compiler.
 */
@:nullSafety(Off)
class NamingConventionCompiler {
    var compiler: ElixirCompiler;

    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }

    public function toElixirName(haxeName: String): String {
        return NamingHelper.toSnakeCase(haxeName);
    }

    public function convertPackageToDirectoryPath(classType: ClassType): String {
        var packageParts = classType.pack;
        var className = classType.name;
        
        // Convert class name to snake_case
        var snakeClassName = NamingHelper.toSnakeCase(className);
        
        if (packageParts.length == 0) {
            // No package - just return snake_case class name
            return snakeClassName;
        }
        
        // Convert package parts to snake_case and join with directories
        var snakePackageParts = packageParts.map(part -> NamingHelper.toSnakeCase(part));
        return haxe.io.Path.join(snakePackageParts.concat([snakeClassName]));
    }

    public function setFrameworkAwareOutputPath(classType: ClassType): Void {
        // Check for framework annotations first
        var annotationInfo = reflaxe.elixir.helpers.AnnotationSystem.detectAnnotations(classType);
        
        if (annotationInfo.primaryAnnotation != null) {
            // Use the comprehensive naming rule for framework annotations
            var namingRule = getComprehensiveNamingRule(classType);
            compiler.setOutputFileName(namingRule.fileName);
            
            // CRITICAL FIX: Prevent Reflaxe framework from receiving empty directory paths
            var safeDir = namingRule.dirPath != null && namingRule.dirPath.length > 0 ? namingRule.dirPath : ".";
            compiler.setOutputFileDir(safeDir);
        } else {
            // Fall back to universal naming for non-annotated classes
            setUniversalOutputPath(classType.name, classType.pack);
        }
    }

    public function getUniversalNamingRule(moduleName: String, pack: Array<String> = null): {fileName: String, dirPath: String} {
        return NamingHelper.getUniversalNamingRule(moduleName, pack);
    }

    public function setUniversalOutputPath(moduleName: String, pack: Array<String> = null): Void {
        var namingRule = getUniversalNamingRule(moduleName, pack);
        // Debug trace removed to avoid test output pollution
        compiler.setOutputFileName(namingRule.fileName);
        
        // CRITICAL FIX: Prevent Reflaxe framework from receiving empty directory paths
        // which can cause "index out of bounds" errors in path processing
        var safeDir = namingRule.dirPath != null && namingRule.dirPath.length > 0 ? namingRule.dirPath : ".";
        compiler.setOutputFileDir(safeDir);
        
        // Debug trace removed to avoid test output pollution
    }

    public function getComprehensiveNamingRule(classType: ClassType): {fileName: String, dirPath: String} {
        return PhoenixPathGenerator.getComprehensiveNamingRule(classType);
    }
}

#end