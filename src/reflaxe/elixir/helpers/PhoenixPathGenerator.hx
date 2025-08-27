package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.ClassType;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.AnnotationSystem;

using StringTools;

/**
 * Phoenix Framework Path Generation Utility
 * 
 * CORE RESPONSIBILITY: Generate Phoenix-compliant file paths and directory structures
 * ============================================================================================
 * 
 * This module consolidates ALL Phoenix path generation logic that was scattered across
 * the main ElixirCompiler. Phoenix has specific conventions for where different types 
 * of files should be placed, and this utility ensures consistency.
 * 
 * WHY: Phoenix applications expect files in specific locations:
 *      - LiveViews: lib/{app}_web/live/{name}_live.ex
 *      - Controllers: lib/{app}_web/controllers/{name}_controller.ex  
 *      - Schemas: lib/{app}/schemas/{name}.ex
 *      - Routers: lib/{app}_web/router.ex (always router.ex)
 *      - Endpoints: lib/{app}_web/endpoint.ex (always endpoint.ex)
 * 
 * WHAT: Provides centralized path generation for all Phoenix file types with:
 *       - Annotation-aware path selection
 *       - Consistent snake_case naming
 *       - App name extraction and standardization
 *       - Package-to-directory conversion
 *       - Framework-specific naming conventions
 * 
 * HOW: Uses annotation detection to determine file type, then applies the appropriate
 *      Phoenix naming convention with proper snake_case conversion and directory structure.
 * 
 * EDGE CASES:
 * - Classes without annotations use default snake_case package structure  
 * - @:native annotations override default naming
 * - Missing app names default to "app"
 * - Router and Endpoint always use singular names (router.ex, endpoint.ex)
 * 
 * @see AnnotationSystem For detecting Phoenix annotations
 * @see NamingHelper For snake_case conversions  
 * @since 1.0.0
 */
class PhoenixPathGenerator {
    
    /**
     * Generate annotation-aware output path with Phoenix conventions
     * 
     * PATH GENERATION MAIN ENTRY POINT
     * 
     * WHY: Different Phoenix file types need specific directory structures and naming.
     *      The compiler was duplicating this logic in multiple places.
     * 
     * WHAT: Detects annotations and generates the appropriate Phoenix-compliant path
     *       for the given class type and output directory.
     * 
     * HOW: 1. Use AnnotationSystem to detect framework annotations
     *      2. Apply framework-specific path generation rules
     *      3. Fall back to default snake_case package structure
     *      4. Return complete path with proper file extension
     * 
     * EDGE CASES:
     * - No annotation: Uses package-to-directory conversion
     * - Unknown annotation: Falls back to default behavior  
     * - @:endpoint uses default path (not special Phoenix location)
     * 
     * @param classType The ClassType being compiled
     * @param outputDir Base output directory (usually "lib/")
     * @param fileExtension File extension (usually ".ex")
     * @return Complete file path following Phoenix conventions
     * @since 1.0.0
     */
    public static function generateAnnotationAwareOutputPath(classType: ClassType, outputDir: String, fileExtension: String): String {
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] ════════════════════════════════════════');
        // trace('[XRay PhoenixPaths] PATH GENERATION START');
        // trace('[XRay PhoenixPaths] Class: ${classType.name}');
        // trace('[XRay PhoenixPaths] Package: ${classType.pack.join(".")}');
        // trace('[XRay PhoenixPaths] Output dir: ${outputDir}');
        #end
        
        var className = classType.name;
        
        // Detect framework annotations using existing AnnotationSystem
        var annotationInfo = AnnotationSystem.detectAnnotations(classType);
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] Primary annotation: ${annotationInfo.primaryAnnotation}');
        #end
        
        if (annotationInfo.primaryAnnotation == null) {
            // No framework annotation - use default snake_case mapping with package-to-directory conversion
            var defaultPath = haxe.io.Path.join([outputDir, convertPackageToDirectoryPath(classType, fileExtension)]);
            
            #if debug_phoenix_paths
            // trace('[XRay PhoenixPaths] ✓ DEFAULT PATH: ${defaultPath}');
            // trace('[XRay PhoenixPaths] ════════════════════════════════════════');
            #end
            
            return defaultPath;
        }
        
        // Generate framework-specific paths based on annotation
        var result = switch (annotationInfo.primaryAnnotation) {
            case ":router":
                generatePhoenixRouterPath(className, outputDir, fileExtension);
            case ":liveview":
                generatePhoenixLiveViewPath(className, outputDir, fileExtension);
            case ":controller":
                generatePhoenixControllerPath(className, outputDir, fileExtension);
            case ":schema":
                generatePhoenixSchemaPath(className, outputDir, fileExtension);
            case ":endpoint":
                // Use default snake_case mapping for @:endpoint - no special Phoenix path needed
                haxe.io.Path.join([outputDir, convertPackageToDirectoryPath(classType, fileExtension)]);
            case _:
                // Unknown annotation - use default snake_case mapping with package-to-directory conversion
                haxe.io.Path.join([outputDir, convertPackageToDirectoryPath(classType, fileExtension)]);
        };
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] ✓ FRAMEWORK PATH: ${result}');
        // trace('[XRay PhoenixPaths] ════════════════════════════════════════');
        #end
        
        return result;
    }
    
    /**
     * Generate Phoenix router path: TodoAppRouter → /lib/todo_app_web/router.ex
     * 
     * PHOENIX ROUTER PATH GENERATION
     * 
     * WHY: Phoenix routers ALWAYS go in {app}_web/router.ex, regardless of class name.
     *      This is a strict Phoenix convention that cannot be changed.
     * 
     * WHAT: Extracts app name from class and generates the canonical router.ex path.
     * 
     * HOW: 1. Extract app name from class name (TodoAppRouter → todo_app)
     *      2. Build {app}_web/router.ex path
     *      3. Join with output directory
     * 
     * EDGE CASES:
     * - Class name without "Router" suffix still works
     * - App name extraction handles multiple suffixes
     * - Always produces router.ex filename (never routers.ex)
     * 
     * @param className Name of the router class
     * @param outputDir Base output directory
     * @param fileExtension File extension (.ex)
     * @return Phoenix router path
     * @since 1.0.0
     */
    public static function generatePhoenixRouterPath(className: String, outputDir: String, fileExtension: String): String {
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] ROUTER PATH GENERATION START');
        // trace('[XRay PhoenixPaths] Class name: ${className}');
        #end
        
        var appName = extractAppName(className);
        var phoenixPath = '${appName}_web/router${fileExtension}';
        var result = haxe.io.Path.join([outputDir, phoenixPath]);
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] Extracted app: ${appName}');
        // trace('[XRay PhoenixPaths] ✓ ROUTER PATH: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Generate Phoenix LiveView path: UserLive → /lib/app_web/live/user_live.ex
     * 
     * PHOENIX LIVEVIEW PATH GENERATION
     * 
     * WHY: Phoenix LiveViews go in {app}_web/live/ directory with {name}_live.ex naming.
     *      This follows Phoenix 1.5+ LiveView conventions.
     * 
     * WHAT: Extracts app name and view name, applies LiveView naming convention.
     * 
     * HOW: 1. Extract app name from class name
     *      2. Remove "Live" suffix and convert to snake_case
     *      3. Build {app}_web/live/{name}_live.ex path
     * 
     * EDGE CASES:
     * - UserLive → user_live.ex (correct)
     * - User → user_live.ex (adds _live suffix)
     * - TodoItemLive → todo_item_live.ex (proper snake_case)
     * 
     * @param className Name of the LiveView class  
     * @param outputDir Base output directory
     * @param fileExtension File extension (.ex)
     * @return Phoenix LiveView path
     * @since 1.0.0
     */
    public static function generatePhoenixLiveViewPath(className: String, outputDir: String, fileExtension: String): String {
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] LIVEVIEW PATH GENERATION START');
        // trace('[XRay PhoenixPaths] Class name: ${className}');
        #end
        
        var appName = extractAppName(className);
        var liveViewName = NamingHelper.toSnakeCase(className.replace("Live", ""));
        var phoenixPath = '${appName}_web/live/${liveViewName}_live${fileExtension}';
        var result = haxe.io.Path.join([outputDir, phoenixPath]);
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] Extracted app: ${appName}');
        // trace('[XRay PhoenixPaths] LiveView name: ${liveViewName}');
        // trace('[XRay PhoenixPaths] ✓ LIVEVIEW PATH: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Generate Phoenix controller path: UserController → /lib/app_web/controllers/user_controller.ex
     * 
     * PHOENIX CONTROLLER PATH GENERATION
     * 
     * WHY: Phoenix controllers go in {app}_web/controllers/ directory with snake_case naming.
     * 
     * WHAT: Extracts app name and converts controller name to snake_case.
     * 
     * HOW: 1. Extract app name from class name
     *      2. Convert full class name to snake_case (preserving Controller suffix)
     *      3. Build {app}_web/controllers/{name}.ex path
     * 
     * EDGE CASES:
     * - UserController → user_controller.ex
     * - TodoItemController → todo_item_controller.ex
     * - API.V1.UsersController → users_controller.ex (complex class names)
     * 
     * @param className Name of the controller class
     * @param outputDir Base output directory
     * @param fileExtension File extension (.ex)
     * @return Phoenix controller path
     * @since 1.0.0
     */
    public static function generatePhoenixControllerPath(className: String, outputDir: String, fileExtension: String): String {
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] CONTROLLER PATH GENERATION START');
        // trace('[XRay PhoenixPaths] Class name: ${className}');
        #end
        
        var appName = extractAppName(className);
        var controllerName = NamingHelper.toSnakeCase(className);
        var phoenixPath = '${appName}_web/controllers/${controllerName}${fileExtension}';
        var result = haxe.io.Path.join([outputDir, phoenixPath]);
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] Extracted app: ${appName}');
        // trace('[XRay PhoenixPaths] Controller name: ${controllerName}');
        // trace('[XRay PhoenixPaths] ✓ CONTROLLER PATH: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Generate Phoenix schema path: User → /lib/app/schemas/user.ex
     * 
     * PHOENIX SCHEMA PATH GENERATION
     * 
     * WHY: Phoenix schemas go in {app}/schemas/ directory (NOT {app}_web).
     *      Schemas are domain models, not web-layer components.
     * 
     * WHAT: Places schemas in the application core, not web layer.
     * 
     * HOW: 1. Extract app name from class name
     *      2. Convert class name to snake_case
     *      3. Build {app}/schemas/{name}.ex path (no _web suffix)
     * 
     * EDGE CASES:
     * - User → user.ex (in schemas/ directory)
     * - TodoItem → todo_item.ex
     * - Account.User → user.ex (complex class names)
     * 
     * @param className Name of the schema class
     * @param outputDir Base output directory
     * @param fileExtension File extension (.ex)
     * @return Phoenix schema path
     * @since 1.0.0
     */
    public static function generatePhoenixSchemaPath(className: String, outputDir: String, fileExtension: String): String {
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] SCHEMA PATH GENERATION START');
        // trace('[XRay PhoenixPaths] Class name: ${className}');
        #end
        
        var appName = extractAppName(className);
        var schemaName = NamingHelper.toSnakeCase(className);
        var phoenixPath = '${appName}/schemas/${schemaName}${fileExtension}';
        var result = haxe.io.Path.join([outputDir, phoenixPath]);
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] Extracted app: ${appName}');
        // trace('[XRay PhoenixPaths] Schema name: ${schemaName}');
        // trace('[XRay PhoenixPaths] ✓ SCHEMA PATH: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Extract app name from class name for Phoenix convention transformation
     * 
     * APP NAME EXTRACTION UTILITY
     * 
     * WHY: Phoenix file paths require the app name (todo_app, my_app, etc.) to build
     *      correct directory structures. Class names often contain this information.
     * 
     * WHAT: Intelligently extracts app name from class names by removing Phoenix suffixes
     *       and applying fallback strategies.
     * 
     * HOW: 1. Check for compiler-defined app_name first
     *      2. Remove common Phoenix suffixes (Router, Live, Controller, etc.)
     *      3. Convert result to snake_case
     *      4. Apply fallback if extraction fails
     * 
     * EDGE CASES:
     * - TodoAppRouter → todo_app
     * - MyAppLive → my_app  
     * - Router (just suffix) → app (fallback)
     * - UserController → user (if no clear app prefix)
     * 
     * Examples: TodoAppRouter → todo_app, MyAppLive → my_app
     * 
     * @param className The class name to extract from
     * @return App name in snake_case format
     * @since 1.0.0
     */
    public static function extractAppName(className: String): String {
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] APP NAME EXTRACTION START');
        // trace('[XRay PhoenixPaths] Input class name: ${className}');
        #end
        
        // First check if we can get app name from compiler defines
        #if (app_name)
        var definedName = haxe.macro.Context.definedValue("app_name");
        // Always convert to snake_case for consistency
        var result = NamingHelper.toSnakeCase(definedName);
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] ✓ COMPILER DEFINED APP NAME: ${result}');
        #end
        
        return result;
        #end
        
        // Remove common Phoenix suffixes first
        var appPart = className.replace("Router", "")
                               .replace("Live", "")
                               .replace("Controller", "")
                               .replace("Schema", "")
                               .replace("Channel", "")
                               .replace("View", "");
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] After suffix removal: ${appPart}');
        #end
        
        // Handle special case where class name is just the suffix (e.g., "Router")
        if (appPart == "") {
            appPart = "app"; // Default fallback
            
            #if debug_phoenix_paths
            // trace('[XRay PhoenixPaths] Empty after suffix removal - using fallback');
            #end
        }
        
        // Convert to snake_case for Elixir conventions
        var result = NamingHelper.toSnakeCase(appPart);
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] ✓ EXTRACTED APP NAME: ${result}');
        #end
        
        return result;
    }
    
    /**
     * Convert Haxe package structure to Elixir directory path with snake_case conversion
     * 
     * PACKAGE-TO-DIRECTORY CONVERSION UTILITY
     * 
     * WHY: Haxe packages need to be mapped to Elixir directory structures with proper
     *      snake_case naming conventions. This was duplicated across the compiler.
     * 
     * WHAT: Converts Haxe package hierarchy to Elixir directory structure with
     *       consistent snake_case naming for both packages and class names.
     * 
     * HOW: 1. Convert class name to snake_case
     *      2. Convert each package part to snake_case
     *      3. Join into directory path with file extension
     *      4. Handle empty packages gracefully
     * 
     * EDGE CASES:
     * - No package: just return snake_case class name
     * - Multi-level packages: MyApp.Models.User → my_app/models/user.ex
     * - CamelCase packages: MyApp.UserService → my_app/user_service.ex
     * 
     * @param classType The ClassType with package information
     * @param fileExtension File extension to append
     * @return Directory path with snake_case naming
     * @since 1.0.0
     */
    public static function convertPackageToDirectoryPath(classType: ClassType, fileExtension: String): String {
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] PACKAGE CONVERSION START');
        // trace('[XRay PhoenixPaths] Class: ${classType.name}');
        // trace('[XRay PhoenixPaths] Package parts: [${classType.pack.join(", ")}]');
        #end
        
        var packageParts = classType.pack;
        var className = classType.name;
        
        // Convert class name to snake_case
        var snakeClassName = NamingHelper.toSnakeCase(className);
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] Snake case class: ${snakeClassName}');
        #end
        
        if (packageParts.length == 0) {
            // No package - just return snake_case class name
            var result = snakeClassName + fileExtension;
            
            #if debug_phoenix_paths
            // trace('[XRay PhoenixPaths] ✓ NO PACKAGE: ${result}');
            #end
            
            return result;
        }
        
        // Convert package parts to snake_case and join with directories
        var snakePackageParts = packageParts.map(part -> NamingHelper.toSnakeCase(part));
        var result = haxe.io.Path.join(snakePackageParts.concat([snakeClassName + fileExtension]));
        
        #if debug_phoenix_paths
        // trace('[XRay PhoenixPaths] Snake package parts: [${snakePackageParts.join(", ")}]');
        // trace('[XRay PhoenixPaths] ✓ FINAL PATH: ${result}');
        #end
        
        return result;
    }
    
    /**
     * COMPREHENSIVE NAMING RULE: Framework annotation-aware path and filename generation
     * 
     * WHY: Different Phoenix components need different path structures based on their role.
     * Phoenix has strict conventions about where files should be placed - LiveViews go
     * in app_web/live/, controllers in app_web/controllers/, schemas in app/schemas/, etc.
     * This centralized function ensures all path generation follows Phoenix conventions.
     * 
     * WHAT: Analyzes class annotations to determine the correct Phoenix path structure:
     * - @:router → router.ex in {app}_web/
     * - @:liveview → {name}_live.ex in {app}_web/live/
     * - @:controller → {name}_controller.ex in {app}_web/controllers/
     * - @:schema → {name}.ex in {app}/schemas/
     * - @:endpoint → endpoint.ex in {app}_web/
     * - @:application → {name}.ex in root lib/ directory
     * - Default → snake_case filename with package-based directory
     * 
     * HOW: 
     * 1. Extract class name and package information
     * 2. Detect Phoenix framework annotations using AnnotationSystem
     * 3. Apply annotation-specific path and filename rules
     * 4. Fall back to universal naming rule for non-Phoenix classes
     * 5. Return structured result with fileName and dirPath
     * 
     * FRAMEWORK INTEGRATION: This function embodies the framework-agnostic design principle.
     * The compiler generates plain Elixir by default, but framework conventions are applied
     * via annotations rather than hardcoded assumptions.
     * 
     * @param classType The Haxe ClassType containing metadata and package information
     * @return Object with fileName and dirPath following Phoenix conventions
     */
    public static function getComprehensiveNamingRule(classType: ClassType): {fileName: String, dirPath: String} {
        var className = classType.name;
        var packageParts = classType.pack;
        var annotationInfo = AnnotationSystem.detectAnnotations(classType);
        
        // Start with the base snake_case file name
        var baseFileName = NamingHelper.toSnakeCase(className);
        
        // Convert package parts to snake_case directories
        var snakePackageParts = packageParts.map(part -> NamingHelper.toSnakeCase(part));
        var packagePath = snakePackageParts.length > 0 ? snakePackageParts.join("/") : "";
        
        // Default rule: snake_case file name with package-based directory
        var rule = {
            fileName: baseFileName,
            dirPath: packagePath
        };
        
        // Apply framework annotation overrides if present
        if (annotationInfo.primaryAnnotation != null) {
            var appName = extractAppName(className);
            
            switch (annotationInfo.primaryAnnotation) {
                case ":router":
                    // TodoAppRouter → router.ex in todo_app_web/
                    rule.fileName = "router";
                    rule.dirPath = appName + "_web";
                    
                case ":liveview":
                    // UserLive → user_live.ex in app_web/live/
                    var liveViewName = baseFileName.replace("_live", "");
                    rule.fileName = liveViewName + "_live";
                    rule.dirPath = appName + "_web/live";
                    
                case ":controller":
                    // UserController → user_controller.ex in app_web/controllers/
                    rule.fileName = baseFileName;
                    rule.dirPath = appName + "_web/controllers";
                    
                case ":schema":
                    // User → user.ex in app/schemas/
                    rule.fileName = baseFileName;
                    rule.dirPath = appName + "/schemas";
                    
                case ":endpoint":
                    // Endpoint → endpoint.ex in app_web/
                    rule.fileName = "endpoint";
                    rule.dirPath = appName + "_web";
                    
                case ":application":
                    // TodoApp → todo_app.ex in lib/ (root)
                    // Special case: for @:application, we want the file named after the class
                    // not the @:native module name
                    rule.fileName = baseFileName;
                    rule.dirPath = ""; // Root lib/ directory
                    
                default:
                    // Other annotations: keep package-based path with snake_case
                    // Already set in default rule
            }
        }
        
        return rule;
    }
}

#end