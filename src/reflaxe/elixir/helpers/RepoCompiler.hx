package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.ClassType;
import reflaxe.elixir.helpers.FormatHelper;
import reflaxe.elixir.helpers.AnnotationSystem;

/**
 * Compiler for @:repo annotated classes
 * Generates idiomatic Ecto.Repo modules with proper configuration
 * 
 * Handles compilation of Haxe classes marked with @:repo annotation
 * to generate Phoenix/Ecto repository modules with PostgreSQL adapter
 * and application-specific configuration.
 */
class RepoCompiler {
    /**
     * Check if a class has @:repo annotation
     */
    public static function isRepoClass(classType: ClassType): Bool {
        return classType.meta.has(":repo");
    }
    
    /**
     * Compile @:repo class to Ecto.Repo module
     * 
     * Generates a standard Ecto repository module with:
     * - use Ecto.Repo with otp_app configuration
     * - PostgreSQL adapter configuration
     * - Proper module documentation
     * 
     * @param classType The Haxe class with @:repo annotation
     * @param className The target Elixir module name
     * @return Generated Elixir module code
     */
    public static function compileRepoModule(classType: ClassType, className: String): String {
        var result = new StringBuf();
        
        // Get app name from annotation
        var appName = AnnotationSystem.getEffectiveAppName(classType);
        var otpApp = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(appName);
        
        // Module definition
        result.add('defmodule ${className} do\n');
        
        // Module documentation
        var docString = 'Database repository for ${appName}\n\n';
        docString += 'Provides type-safe database operations using Ecto patterns.\n';
        docString += 'Configured with PostgreSQL adapter and application-specific settings.';
        
        if (classType.doc != null) {
            docString = classType.doc;
        }
        
        result.add(FormatHelper.formatDoc(docString, true, 1) + '\n');
        
        // Use Ecto.Repo with configuration
        result.add('  use Ecto.Repo,\n');
        result.add('    otp_app: :${otpApp},\n');
        result.add('    adapter: Ecto.Adapters.Postgres\n');
        
        result.add('end');
        
        return result.toString();
    }
    
    /**
     * Generate repository configuration for mix.exs
     * 
     * Returns the configuration block needed in config/config.exs
     * for the repository database connection.
     */
    public static function generateRepoConfig(appName: String): String {
        var otpApp = reflaxe.elixir.helpers.NamingHelper.toSnakeCase(appName);
        var repoModule = '${appName}.Repo';
        
        return 'config :${otpApp}, ${repoModule},\n' +
               '  username: "postgres",\n' +
               '  password: "postgres",\n' +
               '  hostname: "localhost",\n' +
               '  database: "${otpApp}_dev",\n' +
               '  stacktrace: true,\n' +
               '  show_sensitive_data_on_connection_error: true,\n' +
               '  pool_size: 10';
    }
}

#end