package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

/**
 * Build macro for auto-generating router functions from declarative route definitions.
 * 
 * Transforms this declarative syntax:
 * ```haxe
 * @:router
 * @:routes([
 *     {name: "root", method: "LIVE", path: "/", controller: "TodoLive", action: "index"},
 *     {name: "todosList", method: "LIVE", path: "/todos", controller: "TodoLive"}
 * ])
 * class TodoAppRouter {}
 * ```
 * 
 * Into auto-generated functions with proper @:route metadata:
 * ```haxe
 * @:route({method: "LIVE", path: "/", controller: "TodoLive", action: "index"})
 * public static function root(): String { return "/"; }
 * ```
 * 
 * This eliminates the need for empty placeholder functions while maintaining full
 * RouterCompiler compatibility and providing optional type-safe route helpers.
 */
@:nullSafety(Off)
class RouterBuildMacro {
    
    /**
     * Main build macro entry point - generates route functions from @:routes annotation
     */
    public static function generateRoutes(): Array<Field> {
        var fields = Context.getBuildFields();
        var classType = Context.getLocalClass().get();
        
        // Extract route definitions from @:routes annotation
        var routeDefinitions = extractRoutesAnnotation(classType);
        if (routeDefinitions == null || routeDefinitions.length == 0) {
            // No @:routes annotation found - return existing fields unchanged
            trace('RouterBuildMacro: No @:routes annotation found in ${classType.name}');
            return fields;
        }
        
        trace('RouterBuildMacro: Found ${routeDefinitions.length} route definitions in ${classType.name}');
        
        // Validate route definitions
        validateRouteDefinitions(routeDefinitions, classType.pos);
        
        // Generate functions for each route definition
        for (routeDef in routeDefinitions) {
            var generatedFunction = createRouteFunction(routeDef, classType.pos);
            fields.push(generatedFunction);
            trace('RouterBuildMacro: Generated function ${routeDef.name} for route ${routeDef.method} ${routeDef.path}');
        }
        
        trace('RouterBuildMacro: Successfully generated ${routeDefinitions.length} route functions');
        return fields;
    }
    
    /**
     * Extract route definitions from @:routes class annotation
     */
    private static function extractRoutesAnnotation(classType: ClassType): Array<RouteDefinition> {
        if (!classType.meta.has(":routes")) {
            return null;
        }
        
        var routesMetadata = classType.meta.extract(":routes");
        if (routesMetadata.length == 0) {
            return null;
        }
        
        var routesEntry = routesMetadata[0];
        if (routesEntry.params == null || routesEntry.params.length == 0) {
            Context.error("@:routes annotation requires array parameter: @:routes([{...}])", routesEntry.pos);
            return null;
        }
        
        // Parse array of route objects
        var routesArrayExpr = routesEntry.params[0];
        return parseRoutesArray(routesArrayExpr);
    }
    
    /**
     * Parse array expression containing route definitions
     */
    private static function parseRoutesArray(arrayExpr: Expr): Array<RouteDefinition> {
        var routes = [];
        
        switch (arrayExpr.expr) {
            case EArrayDecl(values):
                for (routeExpr in values) {
                    var routeDef = parseRouteObject(routeExpr);
                    if (routeDef != null) {
                        routes.push(routeDef);
                    }
                }
            case _:
                Context.error("@:routes parameter must be an array: @:routes([{...}])", arrayExpr.pos);
        }
        
        return routes;
    }
    
    /**
     * Parse individual route object from expression
     */
    private static function parseRouteObject(routeExpr: Expr): RouteDefinition {
        switch (routeExpr.expr) {
            case EObjectDecl(fields):
                var routeDef = new RouteDefinition();
                
                for (field in fields) {
                    switch (field.field) {
                        case "name":
                            routeDef.name = extractStringValue(field.expr, "name");
                        case "method":
                            routeDef.method = extractStringValue(field.expr, "method");
                        case "path":
                            routeDef.path = extractStringValue(field.expr, "path");
                        case "controller":
                            routeDef.controller = extractStringValue(field.expr, "controller");
                        case "action":
                            routeDef.action = extractStringValue(field.expr, "action");
                        case "pipeline":
                            routeDef.pipeline = extractStringValue(field.expr, "pipeline");
                        case _:
                            Context.warning('Unknown route field: ${field.field}', field.expr.pos);
                    }
                }
                
                return routeDef;
                
            case _:
                Context.error("Route definition must be object: {name: \"...\", method: \"...\", ...}", routeExpr.pos);
                return null;
        }
    }
    
    /**
     * Extract string value from expression
     */
    private static function extractStringValue(expr: Expr, fieldName: String): String {
        switch (expr.expr) {
            case EConst(CString(s, _)):
                return s;
            case _:
                Context.error('${fieldName} must be a string literal', expr.pos);
                return null;
        }
    }
    
    /**
     * Validate route definitions for common errors
     */
    private static function validateRouteDefinitions(routes: Array<RouteDefinition>, pos: Position): Void {
        var usedNames = new Map<String, Bool>();
        var usedPaths = new Map<String, String>();
        
        for (route in routes) {
            // Validate required fields
            if (route.name == null || route.name == "") {
                Context.error("Route missing required 'name' field", pos);
            }
            if (route.method == null || route.method == "") {
                Context.error("Route missing required 'method' field", pos);
            }
            if (route.path == null || route.path == "") {
                Context.error("Route missing required 'path' field", pos);
            }
            
            // Check for duplicate function names
            if (usedNames.exists(route.name)) {
                Context.error('Duplicate route name: ${route.name}', pos);
            }
            usedNames.set(route.name, true);
            
            // Check for duplicate path + method combinations
            var pathMethodKey = '${route.method}:${route.path}';
            if (usedPaths.exists(pathMethodKey)) {
                Context.warning('Duplicate route path/method: ${pathMethodKey} (was ${usedPaths.get(pathMethodKey)})', pos);
            }
            usedPaths.set(pathMethodKey, route.name);
            
            // Validate HTTP method
            var validMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "LIVE", "LIVE_DASHBOARD"];
            if (!validMethods.contains(route.method)) {
                Context.warning('Unknown HTTP method: ${route.method}. Valid: ${validMethods.join(", ")}', pos);
            }
        }
    }
    
    /**
     * Create function field from route definition
     */
    private static function createRouteFunction(routeDef: RouteDefinition, pos: Position): Field {
        // Create @:route annotation for the function
        var routeAnnotation: MetadataEntry = {
            name: ":route",
            params: [createRouteAnnotationObject(routeDef, pos)],
            pos: pos
        };
        
        // Generate function body that returns the path (for route helpers)
        var functionBody: Expr = {
            expr: EReturn({
                expr: EConst(CString(routeDef.path, DoubleQuotes)),
                pos: pos
            }),
            pos: pos
        };
        
        // Create function field
        var functionField: Field = {
            name: routeDef.name,
            access: [APublic, AStatic],
            kind: FFun({
                args: [],
                ret: macro: String,
                expr: functionBody
            }),
            pos: pos,
            meta: [routeAnnotation],
            doc: 'Auto-generated route function for ${routeDef.method} ${routeDef.path}'
        };
        
        return functionField;
    }
    
    /**
     * Create the object expression for @:route annotation
     */
    private static function createRouteAnnotationObject(routeDef: RouteDefinition, pos: Position): Expr {
        var objectFields: Array<ObjectField> = [
            {
                field: "method",
                expr: {expr: EConst(CString(routeDef.method, DoubleQuotes)), pos: pos}
            },
            {
                field: "path", 
                expr: {expr: EConst(CString(routeDef.path, DoubleQuotes)), pos: pos}
            }
        ];
        
        // Add optional fields if present
        if (routeDef.controller != null) {
            objectFields.push({
                field: "controller",
                expr: {expr: EConst(CString(routeDef.controller, DoubleQuotes)), pos: pos}
            });
        }
        
        if (routeDef.action != null) {
            objectFields.push({
                field: "action",
                expr: {expr: EConst(CString(routeDef.action, DoubleQuotes)), pos: pos}
            });
        }
        
        if (routeDef.pipeline != null) {
            objectFields.push({
                field: "pipeline",
                expr: {expr: EConst(CString(routeDef.pipeline, DoubleQuotes)), pos: pos}
            });
        }
        
        return {
            expr: EObjectDecl(objectFields),
            pos: pos
        };
    }
}

/**
 * Route definition structure extracted from @:routes annotation
 */
@:structInit
class RouteDefinition {
    public var name: String;        // Function name (required)
    public var method: String;      // HTTP method: GET, POST, LIVE, etc. (required)  
    public var path: String;        // URL path pattern (required)
    public var controller: String;  // Target controller/LiveView (optional)
    public var action: String;      // Action method (optional)
    public var pipeline: String;    // Pipeline to use (optional)
    
    public function new() {}
}

#end