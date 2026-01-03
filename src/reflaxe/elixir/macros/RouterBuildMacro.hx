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
    // Defer expensive existence checks until after all modules have been typed
    static var pendingControllerChecks:Array<{controller:String, route:String, path:String, pos:Position}> = [];
    static var pendingActionChecks:Array<{controller:String, action:String, route:String, pos:Position}> = [];
    static var afterTypingRegistered:Bool = false;

    static inline function isFastBoot(): Bool {
        #if macro
        return haxe.macro.Context.defined("fast_boot");
        #else
        return false;
        #end
    }
    // Memoization caches for controller/action existence during a single compilation run
    static var ctrlCache: Map<String,Bool> = new Map();
    static var actionCache: Map<String,Bool> = new Map();
    
    /**
     * Main build macro entry point - generates route functions from @:routes annotation
     */
    public static function generateRoutes(): Array<Field> {
        #if debug_perf var __p = reflaxe.elixir.debug.Perf.now(); #end
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        #end
        #if debug_compilation_hang
        // DISABLED: Sys.println('[HANG DEBUG] 🎯 RouterBuildMacro.generateRoutes START');
        var routerStartTime = haxe.Timer.stamp() * 1000;
        #end

        var fields = Context.getBuildFields();
        var classType = Context.getLocalClass().get();

        #if debug_compilation_hang
        // DISABLED: Sys.println('[HANG DEBUG] Router class: ${classType.name}');
        #end

        // Extract route definitions from @:routes annotation
        var routeDefinitions = extractRoutesAnnotation(classType);
        if (routeDefinitions == null || routeDefinitions.length == 0) {
            // No @:routes annotation found - return existing fields unchanged
        #if debug_router_macro trace('RouterBuildMacro: No @:routes annotation found in ${classType.name}'); #end
            return fields;
        }
        
        #if debug_router_macro trace('RouterBuildMacro: Found ${routeDefinitions.length} route definitions in ${classType.name}'); #end
        
        // Validate route definitions (lightweight under fast_boot)
        validateRouteDefinitions(routeDefinitions, classType.pos);
        
        // Generate functions for each route definition
        for (routeDef in routeDefinitions) {
            #if debug_compilation_hang
            // DISABLED: Sys.println('[HANG DEBUG] Generating route: ${routeDef.name} - ${routeDef.method} ${routeDef.path}');
            #end

            var generatedFunction = createRouteFunction(routeDef, classType.pos);
            fields.push(generatedFunction);
            #if debug_router_macro trace('RouterBuildMacro: Generated function ${routeDef.name} for route ${routeDef.method} ${routeDef.path}'); #end
        }
        
        #if debug_router_macro trace('RouterBuildMacro: Successfully generated ${routeDefinitions.length} route functions'); #end

        #if debug_compilation_hang
        var elapsed = (haxe.Timer.stamp() * 1000) - routerStartTime;
        // DISABLED: Sys.println('[HANG DEBUG] ✅ RouterBuildMacro.generateRoutes END - Took ${elapsed}ms, Generated ${routeDefinitions.length} routes');
        #end

        #if hxx_instrument_sys
        var __elapsedMacro = (haxe.Timer.stamp() - __t0) * 1000.0;
        // DISABLED: Sys.println(
            '[MacroTiming] name=RouterBuildMacro.generateRoutes routes='
            + routeDefinitions.length
            + ' elapsed_ms=' + Std.int(__elapsedMacro)
        );
        #end

        #if debug_perf reflaxe.elixir.debug.Perf.add('RouterBuildMacro.generateRoutes', __p); #end
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
	                            routeDef.method = extractMethodValue(field.expr);
	                        case "path":
	                            routeDef.path = extractStringValue(field.expr, "path");
	                        case "controller":
	                            routeDef.controllerIsTypeRef = !isStringLiteral(field.expr);
	                            routeDef.controller = extractControllerValue(field.expr);
	                        case "action":
	                            routeDef.action = extractActionValue(field.expr);
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
	     * Extract string value from expression (supports strings and simple identifiers)
	     */
	    private static function extractStringValue(expr: Expr, fieldName: String): String {
	        switch (expr.expr) {
	            case EConst(CString(s, _)):
	                return s;
	            case EConst(CIdent(ident)):
	                // Handle direct identifiers (class names)
	                return ident;
	            case _:
	                Context.error('${fieldName} must be a string literal or identifier', expr.pos);
	                return null;
	        }
	    }

	    /**
	     * Extract HttpMethod value from expression.
	     *
	     * Supports:
	     * - "GET"
	     * - GET
	     * - HttpMethod.GET
	     * - reflaxe.elixir.macros.HttpMethod.GET
	     */
	    private static function extractMethodValue(expr: Expr): String {
	        return switch (expr.expr) {
	            case EConst(CString(s, _)):
	                s;
	            case EConst(CIdent(ident)):
	                ident;
	            case EField(e, field):
	                var base = extractClassName(e);
	                if (base != null && (base == "HttpMethod" || base.endsWith(".HttpMethod"))) {
	                    field;
	                } else {
	                    Context.error('method must be a string literal or HttpMethod value', expr.pos);
	                    null;
	                }
	            default:
	                Context.error('method must be a string literal or HttpMethod value', expr.pos);
	                null;
	        };
	    }

	    /**
	     * Extract controller module reference from expression.
	     *
	     * Supports:
	     * - "controllers.UserController"
	     * - controllers.UserController
	     * - server.live.TodoLive
	     */
	    private static function extractControllerValue(expr: Expr): String {
	        return switch (expr.expr) {
	            case EConst(CString(s, _)):
	                s;
	            default:
	                var path = extractClassName(expr);
	                if (path == null) {
	                    Context.error('controller must be a string literal or type reference (e.g. controllers.UserController)', expr.pos);
	                    null;
	                } else {
	                    path;
	                }
	        };
	    }

	    /**
	     * Extract action reference from expression.
	     *
	     * Supports:
	     * - "index"
	     * - index
	     * - TodoLive.index
	     * - server.live.TodoLive.index
	     */
	    private static function extractActionValue(expr: Expr): String {
	        return switch (expr.expr) {
	            case EConst(CString(s, _)):
	                s;
	            case EConst(CIdent(ident)):
	                ident;
	            case EField(_, field):
	                field;
	            default:
	                Context.error('action must be a string literal, identifier, or method reference (e.g. TodoLive.index)', expr.pos);
	                null;
	        };
	    }
    
	    /**
	     * Extract class name from expression
	     */
	    private static function extractClassName(expr: Expr): String {
	        return switch (expr.expr) {
	            case EConst(CIdent(ident)):
	                ident;
	            case EField(e, field):
	                var base = extractClassName(e);
	                base != null ? (base + "." + field) : field;
	            default:
	                null;
	        };
	    }

	    static inline function isStringLiteral(expr: Expr): Bool {
	        return switch (expr.expr) {
	            case EConst(CString(_, _)): true;
	            default: false;
	        };
	    }
    
    /**
     * Validate route definitions for common errors
     */
	    private static function validateRouteDefinitions(routes: Array<RouteDefinition>, pos: Position): Void {
        var usedNames = new Map<String, Bool>();
        var usedPaths = new Map<String, String>();
        var fastBoot = isFastBoot();

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
            var validMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "LIVE", "LIVE_DASHBOARD", "MAILBOX"];
            if (!validMethods.contains(route.method)) {
                Context.warning('Unknown HTTP method: ${route.method}. Valid: ${validMethods.join(", ")}', pos);
            }
            
	            // Skip expensive type checks under fast_boot; keep warnings lightweight
	            if (!fastBoot) {
	                if (route.controllerIsTypeRef && route.controller != null && route.controller != "") {
	                    pendingControllerChecks.push({
	                        controller: route.controller,
	                        route: route.name,
	                        path: route.path,
	                        pos: pos
	                    });
	                }
	                if (route.controllerIsTypeRef && route.controller != null && route.action != null && route.controller != "" && route.action != "") {
	                    pendingActionChecks.push({
	                        controller: route.controller,
	                        action: route.action,
	                        route: route.name,
	                        pos: pos
	                    });
	                }

	                ensureAfterTypingHook();
	            }
	        }
    }

    /**
     * Register a single onAfterTyping hook to run queued controller/action checks
     * after all modules are fully typed. This avoids "module not ready" errors
     * when routes reference LiveView modules being compiled in the same pass.
     */
    static function ensureAfterTypingHook():Void {
        if (afterTypingRegistered) return;
        afterTypingRegistered = true;

        Context.onAfterTyping(function(_) {
            // Validate controllers
            for (entry in pendingControllerChecks) {
                validateControllerExists(entry.controller, entry.route, entry.path, entry.pos);
            }
            pendingControllerChecks = [];

            // Validate actions
            for (entry in pendingActionChecks) {
                validateActionExists(entry.controller, entry.action, entry.route, entry.pos);
            }
            pendingActionChecks = [];
        });
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
    
    /**
     * Validate that a controller class exists
     */
	    private static function validateControllerExists(controllerName: String, routeName: String, routePath: String, pos: Position): Void {
	        if (controllerName == null || controllerName == "") return;
	        if (ctrlCache.exists(controllerName)) return;

	        try {
	            Context.getType(controllerName);
	        } catch (e: Dynamic) {
	            Context.error('Router DSL error: controller type not found "${controllerName}" for route "${routeName}" (${routePath})', pos);
	        }

	        ctrlCache.set(controllerName, true);
	    }
    
    /**
     * Validate that an action method exists on the controller
     */
	    private static function validateActionExists(controllerName: String, actionName: String, routeName: String, pos: Position): Void {
	        if (controllerName == null || actionName == null || controllerName == "" || actionName == "") return;
	        var key = controllerName + "#" + actionName;
	        if (actionCache.exists(key)) return; // already validated

	        var action = actionName;
	        if (action.startsWith(":")) action = action.substr(1);

	        var t: Null<Type> = null;
	        try {
	            t = Context.getType(controllerName);
	        } catch (e: Dynamic) {
	            // Controller error is reported by validateControllerExists; don't cascade.
	            actionCache.set(key, true);
	            return;
	        }

	        var controllerClass: Null<ClassType> = switch (t) {
	            case TInst(c, _): c.get();
	            case TType(tdef, _): switch (tdef.get().type) { case TInst(c, _): c.get(); default: null; }
	            default: null;
	        };

	        if (controllerClass != null) {
	            var statics = controllerClass.statics.get();
	            var found = false;
	            for (f in statics) {
	                if (f.name == action) {
	                    found = true;
	                    break;
	                }
	            }
	            if (!found) {
	                Context.error('Router DSL error: action "${action}" not found on controller "${controllerName}" (route "${routeName}")', pos);
	            }
	        }

	        actionCache.set(key, true);
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
    public var controllerIsTypeRef: Bool; // true when controller is expressed as a type ref (not a string literal)
    
    public function new() {}
}

#end
