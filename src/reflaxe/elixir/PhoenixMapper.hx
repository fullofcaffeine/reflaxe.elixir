package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
// Using centralized NameUtils for name conversion
import reflaxe.elixir.ast.NameUtils;

using StringTools;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.TypeHelper;

/**
 * Phoenix-specific compilation features and transformations
 * Handles context annotations, Phoenix conventions, and framework integrations
 */
@:nullSafety(Off)
class PhoenixMapper {
    
    
    /**
     * Check if a class has @:context annotation for Phoenix context generation
     */
    public static function isPhoenixContext(classType: ClassType): Bool {
        return classType.hasMeta(":context");
    }
    
    /**
     * Check if a class extends Phoenix.Controller
     */
    public static function isPhoenixController(classType: ClassType): Bool {
        if (classType.superClass == null) return false;
        var superClassName = classType.superClass.t.get().getNameOrNative();
        return superClassName.contains("Phoenix.Controller") || superClassName.contains("PhoenixController");
    }
    
    /**
     * Check if a class extends Phoenix.LiveView
     */
    public static function isPhoenixLiveView(classType: ClassType): Bool {
        if (classType.superClass == null) return false;
        var superClassName = classType.superClass.t.get().getNameOrNative();
        return superClassName.contains("Phoenix.LiveView") || superClassName.contains("PhoenixLiveView");
    }
    
    /**
     * Generate Phoenix context module structure
     * Contexts organize related functionality and follow Phoenix conventions
     */
    public static function generatePhoenixContext(classType: ClassType): String {
        var moduleName = NameUtils.getElixirModuleName(classType.getNameOrNative());
        var contextName = getPhoenixContextName(classType);
        
        var result = new StringBuf();
        result.add('defmodule ${moduleName} do\n');
        result.add('  @moduledoc """\n');
        result.add('  The ${contextName} context - Generated from Haxe @:context class\n');
        result.add('  """\n\n');
        
        // Add standard Phoenix context imports
        result.add('  import Ecto.Query, warn: false\n');
        result.add('  alias ${getRepoModuleName()}\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate Phoenix controller module structure
     */
    public static function generatePhoenixController(classType: ClassType): String {
        var moduleName = NameUtils.getElixirModuleName(classType.getNameOrNative());
        
        var result = new StringBuf();
        result.add('defmodule ${moduleName} do\n');
        result.add('  use ${getAppModuleName()}Web, :controller\n\n');
        result.add('  @moduledoc """\n');
        result.add('  Phoenix Controller - Generated from Haxe\n');
        result.add('  """\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate Phoenix LiveView module structure
     */
    public static function generatePhoenixLiveView(classType: ClassType): String {
        var moduleName = NameUtils.getElixirModuleName(classType.getNameOrNative());
        
        var result = new StringBuf();
        result.add('defmodule ${moduleName} do\n');
        result.add('  use ${getAppModuleName()}Web, :live_view\n\n');
        result.add('  @moduledoc """\n');
        result.add('  Phoenix LiveView - Generated from Haxe\n');
        result.add('  """\n\n');
        
        // Add standard LiveView imports
        result.add('  import Phoenix.LiveView.Helpers\n');
        result.add('  alias Phoenix.LiveView.Socket\n\n');
        
        return result.toString();
    }
    
    /**
     * Generate Ecto schema imports and aliases for Phoenix contexts
     */
    public static function generateEctoImports(): String {
        var result = new StringBuf();
        result.add('  import Ecto\n');
        result.add('  import Ecto.Changeset\n');
        result.add('  import Ecto.Query\n\n');
        return result.toString();
    }
    
    /**
     * Get Phoenix context name from class metadata or class name
     */
    public static function getPhoenixContextName(classType: ClassType): String {
        // Check for custom context name in metadata
        var contextMeta = classType.meta.extract(":context");
        if (contextMeta.length > 0 && contextMeta[0].params != null && contextMeta[0].params.length > 0) {
            switch (contextMeta[0].params[0].expr) {
                case EConst(CString(s, _)): return s;
                default:
            }
        }
        
        // Default to class name without "Context" suffix
        var className = classType.getNameOrNative();
        if (className.endsWith("Context")) {
            className = className.substr(0, className.length - 7);
        }
        return className;
    }
    
    /**
     * Get the application's Repo module name
     * Configurable via -D app_name compiler flag, defaults to MyApp.Repo
     */
    public static function getRepoModuleName(): String {
        #if app_name
        return haxe.macro.Compiler.getDefine("app_name") + ".Repo";
        #else
        return "MyApp.Repo";
        #end
    }
    
    /**
     * Get the application's main module name  
     * Configurable via -D app_name compiler flag, defaults to MyApp
     */
    public static function getAppModuleName(): String {
        #if app_name
        return haxe.macro.Compiler.getDefine("app_name");
        #else
        return "MyApp";
        #end
    }
    
    /**
     * Generate Phoenix naming conventions for URLs and paths
     */
    public static function getPhoenixResourceName(className: String): String {
        // Convert UserController -> users, PostController -> posts
        var name = className;
        if (name.endsWith("Controller")) {
            name = name.substr(0, name.length - 10);
        }
        
        // Pluralize and convert to snake_case
        var snakeName = NameUtils.toSnakeCase(name);
        return pluralize(snakeName);
    }
    
    /**
     * Simple pluralization for Phoenix resource names
     */
    private static function pluralize(singular: String): String {
        // Basic English pluralization rules
        if (singular.endsWith("y")) {
            return singular.substr(0, singular.length - 1) + "ies";
        } else if (singular.endsWith("s") || singular.endsWith("sh") || singular.endsWith("ch")) {
            return singular + "es";
        } else {
            return singular + "s";
        }
    }
}

#end