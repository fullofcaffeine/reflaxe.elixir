package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.macros.ModuleFieldMetadataRegistry;

/**
 * Bootstrap strategy for module loading
 */
enum BootstrapStrategy {
	None; // No bootstrap needed
	InlineDeterministic; // Inline require statements
	External; // External bootstrap file
}

/**
 * ModuleBuilder: Builds Elixir module structures
 *
 * WHY: Module generation is complex with many concerns: naming, imports,
 * attributes, functions, and bootstrap strategies. This builder centralizes
 * that logic.
 *
 * WHAT: Handles all aspects of Elixir module generation including defmodule
 * structure, use statements, imports, and bootstrap code generation.
 *
 * HOW: Provides a builder API for constructing modules piece by piece,
 * then generates the appropriate AST structure.
 *
 * ARCHITECTURE BENEFITS:
 * - Single responsibility for module generation
 * - Consistent module structure across all types
 * - Bootstrap strategy abstraction
 *
 * NOTE: This is a CONSERVATIVE stub implementation for Phase 2 integration.
 * Returns minimal, safe module structures. Full implementation in Phase 3.
 */
class ModuleBuilder {
	private static var bootstrapStrategy:BootstrapStrategy = None;

	/**
	 * Get the current bootstrap strategy
	 */
	public static function getBootstrapStrategy():BootstrapStrategy {
		return bootstrapStrategy;
	}

	/**
	 * Set the bootstrap strategy
	 */
	public static function setBootstrapStrategy(strategy:BootstrapStrategy):Void {
		bootstrapStrategy = strategy;
	}

	/**
	 * Extract module name from a ClassType
	 *
	 * @param classType The class to extract name from
	 * @return The module name
	 */
	public static function extractModuleName(classType:ClassType):String {
		var nativeMeta = collectClassAndModuleMetadata(classType, ":native", "native");

		// Check for @:native annotation first
		if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
			switch (nativeMeta[0].params[0].expr) {
				case EConst(CString(s, _)):
					// Prefer idiomatic module aliases (String) over fully-qualified internal names (Elixir.String).
					return StringTools.startsWith(s, "Elixir.") ? s.substr("Elixir.".length) : s;
				default:
			}
		}

		var appName = reflaxe.elixir.PhoenixMapper.getAppModuleName();
		if (hasClassOrModuleMetadata(classType, ":router", "router") && appName != null && appName != "") {
			return appName + "Web.Router";
		}
		if (hasClassOrModuleMetadata(classType, ":endpoint", "endpoint") && appName != null && appName != "") {
			return appName + "Web.Endpoint";
		}
		if ((hasClassOrModuleMetadata(classType, ":phoenixWebModule", "phoenixWebModule")
			|| hasClassOrModuleMetadata(classType, ":phoenixWeb", "phoenixWeb"))
			&& appName != null
			&& appName != "") {
			return appName + "Web";
		}

		// For @:application classes without @:native, append ".Application" to module name
		// This follows Phoenix/OTP convention where applications are named AppName.Application
		if (hasClassOrModuleMetadata(classType, ":application", "application") && nativeMeta.length == 0) {
			if (appName != null && appName != "")
				return appName + ".Application";
			return classType.name + ".Application";
		}

		// Migration emission mode: migrations are compiled into `priv/repo/migrations/*.exs`.
		// Ecto convention is `MyApp.Repo.Migrations.*`, so we force that namespace when
		// `-D ecto_migrations_exs` is enabled.
		if (Context.defined("ecto_migrations_exs") && classType.meta.has(":migration")) {
			var migrationAppName = reflaxe.elixir.PhoenixMapper.getAppModuleName();
			return migrationAppName + ".Repo.Migrations." + classType.name;
		}

		// For non-extern project code in a packaged namespace, qualify with the configured app module prefix.
		//
		// This is intentionally conservative: we only apply the prefix when `-D app_name=...` is present.
		// Without app_name, keep prior behavior (emit unqualified module names) for minimal examples.
		//
		// IMPORTANT: Do not prefix Haxe stdlib/runtime modules (haxe.* / sys.*). Those are emitted as
		// unqualified modules (e.g., `Log`, `BalancedTree`) and are referenced unqualified by the runtime.
		if (!classType.isExtern && classType.pack.length > 0 && classType.pack[0] != "haxe" && classType.pack[0] != "sys" && classType.pack[0] != "elixir"
			&& classType.pack[0] != "ecto" && classType.pack[0] != "phoenix" && classType.pack[0] != "plug") {
			var configuredAppName = Context.definedValue("app_name");
			if (configuredAppName != null && configuredAppName != "") {
				return configuredAppName + "." + classType.name;
			}
		}

		// Default to class name
		return classType.name;
	}

	static function collectClassAndModuleMetadata(classType:ClassType, primaryName:String, alternateName:String):Array<MetadataEntry> {
		var entries:Array<MetadataEntry> = [];

		var classPrimary = classType.meta.extract(primaryName);
		if (classPrimary != null && classPrimary.length > 0)
			entries = entries.concat(classPrimary);

		var classAlternate = classType.meta.extract(alternateName);
		if (classAlternate != null && classAlternate.length > 0)
			entries = entries.concat(classAlternate);

		switch (classType.kind) {
			case KModuleFields(_):
				for (staticField in classType.statics.get()) {
					var staticPrimary = staticField.meta.extract(primaryName);
					if (staticPrimary != null && staticPrimary.length > 0)
						entries = entries.concat(staticPrimary);

					var staticAlternate = staticField.meta.extract(alternateName);
					if (staticAlternate != null && staticAlternate.length > 0)
						entries = entries.concat(staticAlternate);
				}
			default:
		}

		var moduleFieldMetadata = ModuleFieldMetadataRegistry.extractMetadata(classType, primaryName, alternateName);
		if (moduleFieldMetadata != null && moduleFieldMetadata.length > 0)
			entries = entries.concat(moduleFieldMetadata);

		return entries;
	}

	static inline function hasClassOrModuleMetadata(classType:ClassType, primaryName:String, alternateName:String):Bool {
		return collectClassAndModuleMetadata(classType, primaryName, alternateName).length > 0;
	}

	/**
	 * Build a class module AST with support for exception classes
	 *
	 * @param classType The class type to compile
	 * @param fields Module fields (functions, properties, etc.)
	 * @param metadata Optional metadata containing inheritance info
	 * @return Module AST with appropriate structure (regular module or exception)
	 * 
	 * @example Building a regular class:
	 * ```haxe
	 * var moduleAST = ModuleBuilder.buildClassModule(classType, fields, null);
	 * ```
	 * 
	 * @example Building an exception class:
	 * ```haxe
	 * var metadata = { isException: true, parentModule: "Exception" };
	 * var moduleAST = ModuleBuilder.buildClassModule(classType, fields, metadata);
	 * ```
	 */
	public static function buildClassModule(classType:ClassType, fields:Array<ElixirAST>, ?metadata:ElixirMetadata):ElixirAST {
		#if debug_compilation_hang
		var moduleStartTime = haxe.Timer.stamp() * 1000;
		#end

		var moduleName = extractModuleName(classType);
		// Register module globally for cross-file qualification
		try {
			reflaxe.elixir.ElixirCompiler.registerModule(moduleName);
			// Also register app-prefixed variant for Web-context qualification,
			// e.g., TodoApp + "." + Todo -> "TodoApp.Todo"
			var app = reflaxe.elixir.PhoenixMapper.getAppModuleName();
			if (app != null && app.length > 0 && moduleName.indexOf('.') == -1) {
				reflaxe.elixir.ElixirCompiler.registerModule(app + "." + moduleName);
			}
		} catch (e) {}
		var attributes:Array<EAttribute> = [];

		// Use provided metadata or create empty object
		var moduleMetadata = metadata != null ? metadata : {};

		// Check if this is an exception class
		if (moduleMetadata.isException == true) {
			#if debug_inheritance
			#end

			// Don't add defstruct for exceptions - defexception handles it automatically
			// The ElixirASTPrinter will handle the defexception macro when it sees isException metadata
			// Just keep the regular fields (methods like toString)
		}

		var result = {
			def: EModule(moduleName, attributes, fields),
			metadata: moduleMetadata,
			pos: classType.pos
		};

		#if debug_compilation_hang
		var elapsed = (haxe.Timer.stamp() * 1000) - moduleStartTime;
		#end

		return result;
	}

	/**
	 * Create the defstruct definition for exception classes
	 * 
	 * @return AST node representing defstruct with message field
	 * 
	 * Generates: `defstruct message: ""`
	 */
	static function makeExceptionStructDefinition():ElixirAST {
		// Create the struct definition with message field
		// This simulates defexception which creates a struct with message
		return makeAST(ECall(null, "defstruct", [makeAST(EKeywordList([{key: "message", value: makeAST(EString(""))}]))]));
	}

	/**
	 * Helper function to create AST nodes
	 * 
	 * @param def The AST definition
	 * @return ElixirAST node with empty metadata
	 */
	static inline function makeAST(def:ElixirASTDef):ElixirAST {
		return {
			def: def,
			metadata: {},
			pos: null
		};
	}
}
#end
