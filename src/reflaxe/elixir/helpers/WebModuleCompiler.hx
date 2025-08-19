package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.ClassType;
import reflaxe.elixir.helpers.FormatHelper;
import reflaxe.elixir.helpers.AnnotationSystem;

/**
 * Compiler for @:phoenixWebModule annotated classes
 * Generates Phoenix web modules with macro definitions for router, controller, live_view, etc.
 * 
 * This compiler handles the complex Phoenix meta-programming requirements by generating
 * Elixir macros and quoted expressions that Phoenix applications need for their
 * use TodoAppWeb, :router / :controller / :live_view patterns.
 * 
 * The generated module provides:
 * - defmacro __using__(which) - Main dispatch macro
 * - def router/0 - Returns quoted Phoenix.Router configuration
 * - def controller/0 - Returns quoted Phoenix.Controller configuration
 * - def live_view/0 - Returns quoted Phoenix.LiveView configuration
 * - def live_component/0 - Returns quoted Phoenix.LiveComponent configuration
 * - def html/0 - Returns quoted Phoenix.Component configuration
 * - defp html_helpers/0 - Private helper for common HTML imports
 * - def verified_routes/0 - Returns quoted Phoenix.VerifiedRoutes configuration
 */
class WebModuleCompiler {
    /**
     * Check if a class has @:phoenixWebModule annotation
     */
    public static function isWebModuleClass(classType: ClassType): Bool {
        return classType.meta.has(":phoenixWebModule");
    }
    
    /**
     * Compile @:phoenixWebModule class to Phoenix web module with all necessary macros
     * 
     * @param classType The Haxe class with @:phoenixWebModule annotation
     * @param className The target Elixir module name
     * @return Generated Elixir module code with all Phoenix macros
     */
    public static function compileWebModule(classType: ClassType, className: String): String {
        var result = new StringBuf();
        
        // Get app name from annotation
        var appName = AnnotationSystem.getEffectiveAppName(classType);
        var otpApp = appName.toLowerCase();
        var webModule = '${appName}Web';
        
        // Module definition
        result.add('defmodule ${className} do\n');
        
        // Module documentation
        var docString = 'The entrypoint for defining your web interface, such\n';
        docString += 'as controllers, components, channels, and so on.\n\n';
        docString += 'This can be used in your application as:\n\n';
        docString += '    use ${webModule}, :controller\n';
        docString += '    use ${webModule}, :html\n\n';
        docString += 'The definitions below will be executed for every controller,\n';
        docString += 'component, etc, so keep them short and clean, focused\n';
        docString += 'on imports, uses and aliases.\n\n';
        docString += 'Do NOT define functions inside the quoted expressions\n';
        docString += 'below. Instead, define additional modules and import\n';
        docString += 'those modules here.';
        
        if (classType.doc != null) {
            docString = classType.doc;
        }
        
        result.add(FormatHelper.formatDoc(docString, true, 1) + '\n');
        
        // Generate static_paths function
        result.add('  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)\n\n');
        
        // Generate router/0 function
        result.add('  def router do\n');
        result.add('    quote do\n');
        result.add('      use Phoenix.Router, helpers: false\n\n');
        result.add('      # Import common connection and controller functions to use in pipelines\n');
        result.add('      import Plug.Conn\n');
        result.add('      import Phoenix.Controller\n');
        result.add('      import Phoenix.LiveView.Router\n');
        result.add('    end\n');
        result.add('  end\n\n');
        
        // Generate channel/0 function
        result.add('  def channel do\n');
        result.add('    quote do\n');
        result.add('      use Phoenix.Channel\n');
        result.add('    end\n');
        result.add('  end\n\n');
        
        // Generate controller/0 function
        result.add('  def controller do\n');
        result.add('    quote do\n');
        result.add('      use Phoenix.Controller,\n');
        result.add('        formats: [:html, :json],\n');
        result.add('        layouts: [html: ${webModule}.Layouts]\n\n');
        result.add('      import Plug.Conn\n');
        result.add('      import ${webModule}.Gettext\n\n');
        result.add('      unquote(verified_routes())\n');
        result.add('    end\n');
        result.add('  end\n\n');
        
        // Generate live_view/0 function
        result.add('  def live_view do\n');
        result.add('    quote do\n');
        result.add('      use Phoenix.LiveView,\n');
        result.add('        layout: {${webModule}.Layouts, :app}\n\n');
        result.add('      unquote(html_helpers())\n');
        result.add('    end\n');
        result.add('  end\n\n');
        
        // Generate live_component/0 function
        result.add('  def live_component do\n');
        result.add('    quote do\n');
        result.add('      use Phoenix.LiveComponent\n\n');
        result.add('      unquote(html_helpers())\n');
        result.add('    end\n');
        result.add('  end\n\n');
        
        // Generate html/0 function
        result.add('  def html do\n');
        result.add('    quote do\n');
        result.add('      use Phoenix.Component\n\n');
        result.add('      # Import convenience functions from controllers\n');
        result.add('      import Phoenix.Controller,\n');
        result.add('        only: [get_csrf_token: 0, view_module: 1, view_template: 1]\n\n');
        result.add('      # Include general helpers for rendering HTML\n');
        result.add('      unquote(html_helpers())\n');
        result.add('    end\n');
        result.add('  end\n\n');
        
        // Generate html_helpers/0 private function
        result.add('  defp html_helpers do\n');
        result.add('    quote do\n');
        result.add('      # HTML escaping functionality\n');
        result.add('      import Phoenix.HTML\n');
        result.add('      # Core UI components and translation functions\n');
        result.add('      import ${webModule}.CoreComponents\n');
        result.add('      import ${webModule}.Gettext\n\n');
        result.add('      # Shortcut for generating JS commands\n');
        result.add('      alias Phoenix.LiveView.JS\n\n');
        result.add('      # Routes generation with the ~p sigil\n');
        result.add('      unquote(verified_routes())\n');
        result.add('    end\n');
        result.add('  end\n\n');
        
        // Generate verified_routes/0 function
        result.add('  def verified_routes do\n');
        result.add('    quote do\n');
        result.add('      use Phoenix.VerifiedRoutes,\n');
        result.add('        endpoint: ${webModule}.Endpoint,\n');
        result.add('        router: ${webModule}.Router,\n');
        result.add('        statics: ${webModule}.static_paths()\n');
        result.add('    end\n');
        result.add('  end\n\n');
        
        // Generate __using__ macro
        result.add('  @doc """\n');
        result.add('  When used, dispatch to the appropriate controller/view/etc.\n');
        result.add('  """\n');
        result.add('  defmacro __using__(which) when is_atom(which) do\n');
        result.add('    apply(__MODULE__, which, [])\n');
        result.add('  end\n');
        
        result.add('end');
        
        return result.toString();
    }
}

#end