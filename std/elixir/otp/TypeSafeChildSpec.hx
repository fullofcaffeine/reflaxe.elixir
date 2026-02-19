package elixir.otp;

import elixir.otp.Supervisor.ChildSpecFormat;
import elixir.otp.Supervisor.ChildSpec;
import elixir.types.Term;
#if macro
import haxe.macro.Expr;
#end

/**
 * Type-safe child specifications for OTP supervisors.
 *
 * WHY
 * - Child specs are foundational app wiring; weak string-based APIs make mistakes easy.
 * - Typed module refs catch misspelled/unresolvable modules at compile time.
 *
 * WHAT
 * - Primary APIs accept module type references (class/extern), resolved at compile time.
 * - Explicit `*Unsafe` variants keep interop available when dynamic strings are intentional.
 *
 * HOW
 * - Typed macro entry points resolve module refs to Elixir module names.
 * - Runtime child-spec shapes remain the same (`ModuleRef`, `{Module, kw}`, full spec maps).
 *
 * EXAMPLES
 * Haxe (typed):
 *   TypeSafeChildSpec.endpoint(server.infrastructure.Endpoint)
 *   TypeSafeChildSpec.pubSub(server.infrastructure.PubSub)
 *
 * Haxe (explicit escape hatch):
 *   TypeSafeChildSpec.endpointUnsafe("MyAppWeb.Endpoint")
 */
class TypeSafeChildSpec {
	/**
	 * Phoenix PubSub child specification (typed module reference).
	 */
	public static macro function pubSub(moduleRef:Expr):ExprOf<ChildSpecFormat> {
		var moduleName = elixir.otp.macros.ChildSpecModuleResolver.resolveModuleName(moduleRef, "TypeSafeChildSpec.pubSub", "TypeSafeChildSpec.pubSubUnsafe");
		return macro TypeSafeChildSpec.pubSubUnsafe($v{moduleName});
	}

	/**
	 * Explicit dynamic escape hatch for PubSub module names.
	 */
	public static inline function pubSubUnsafe(name:String):ChildSpecFormat {
		return ModuleWithConfig("Phoenix.PubSub", [{key: "name", value: name}]);
	}

	/**
	 * Ecto repository child specification (typed module reference).
	 */
	public static macro function repo(moduleRef:Expr, ?config:Expr):ExprOf<ChildSpecFormat> {
		var moduleName = elixir.otp.macros.ChildSpecModuleResolver.resolveModuleName(moduleRef, "TypeSafeChildSpec.repo", "TypeSafeChildSpec.repoUnsafe");
		var configExpr = config != null ? config : macro null;
		return macro TypeSafeChildSpec.repoUnsafe($v{moduleName}, $configExpr);
	}

	/**
	 * Explicit dynamic escape hatch for repo module names.
	 */
	public static inline function repoUnsafe(module:String, ?config:Array<{key:String, value:Term}>):ChildSpecFormat {
		if (config != null) {
			return ModuleWithConfig(module, config);
		}
		return ModuleRef(module);
	}

	/**
	 * Phoenix endpoint child specification (typed module reference).
	 */
	public static macro function endpoint(moduleRef:Expr):ExprOf<ChildSpecFormat> {
		var moduleName = elixir.otp.macros.ChildSpecModuleResolver.resolveModuleName(moduleRef, "TypeSafeChildSpec.endpoint",
			"TypeSafeChildSpec.endpointUnsafe");
		return macro TypeSafeChildSpec.endpointUnsafe($v{moduleName});
	}

	/**
	 * Explicit dynamic escape hatch for endpoint module names.
	 */
	public static inline function endpointUnsafe(module:String):ChildSpecFormat {
		return ModuleRef(module);
	}

	/**
	 * Telemetry child specification (typed module reference).
	 */
	public static macro function telemetry(moduleRef:Expr):ExprOf<ChildSpecFormat> {
		var moduleName = elixir.otp.macros.ChildSpecModuleResolver.resolveModuleName(moduleRef, "TypeSafeChildSpec.telemetry",
			"TypeSafeChildSpec.telemetryUnsafe");
		return macro TypeSafeChildSpec.telemetryUnsafe($v{moduleName});
	}

	/**
	 * Explicit dynamic escape hatch for telemetry module names.
	 */
	public static inline function telemetryUnsafe(module:String):ChildSpecFormat {
		return ModuleRef(module);
	}

	/**
	 * Generic worker child specification (typed module reference).
	 */
	public static macro function worker(moduleRef:Expr, ?args:Expr):ExprOf<ChildSpecFormat> {
		var moduleName = elixir.otp.macros.ChildSpecModuleResolver.resolveModuleName(moduleRef, "TypeSafeChildSpec.worker", "TypeSafeChildSpec.workerUnsafe");
		var argsExpr = args != null ? args : macro null;
		return macro TypeSafeChildSpec.workerUnsafe($v{moduleName}, $argsExpr);
	}

	/**
	 * Explicit dynamic escape hatch for worker module names.
	 */
	public static inline function workerUnsafe(module:String, ?args:Array<Term>):ChildSpecFormat {
		if (args != null && args.length > 0) {
			return ModuleWithArgs(module, args);
		}
		return ModuleRef(module);
	}

	/**
	 * Generic supervisor child specification (typed module reference).
	 */
	public static macro function supervisor(moduleRef:Expr, ?args:Expr, ?opts:Expr):ExprOf<ChildSpecFormat> {
		var moduleName = elixir.otp.macros.ChildSpecModuleResolver.resolveModuleName(moduleRef, "TypeSafeChildSpec.supervisor",
			"TypeSafeChildSpec.supervisorUnsafe");
		var argsExpr = args != null ? args : macro null;
		var optsExpr = opts != null ? opts : macro null;
		return macro TypeSafeChildSpec.supervisorUnsafe($v{moduleName}, $argsExpr, $optsExpr);
	}

	/**
	 * Explicit dynamic escape hatch for supervisor module names.
	 */
	public static inline function supervisorUnsafe(module:String, ?args:Array<Term>, ?opts:ChildSpec):ChildSpecFormat {
		if (opts != null) {
			var spec = opts;
			spec.id = module;
			spec.start = {module: module, func: "start_link", args: args != null ? args : []};
			if (spec.type == null)
				spec.type = Supervisor;
			return FullSpec(spec);
		}
		if (args != null && args.length > 0) {
			return ModuleWithArgs(module, args);
		}
		return ModuleRef(module);
	}

	/**
	 * Task supervisor child specification.
	 */
	public static inline function taskSupervisor(name:String):ChildSpecFormat {
		return ModuleWithConfig("Task.Supervisor", [{key: "name", value: name}]);
	}

	/**
	 * Registry child specification.
	 */
	public static inline function registry(name:String, ?opts:Array<{key:String, value:Term}>):ChildSpecFormat {
		var config = [{key: "name", value: name}];
		if (opts != null) {
			config = config.concat(opts);
		}
		return ModuleWithConfig("Registry", config);
	}

	/**
	 * Generic typed wrapper for ChildSpecFormat.ModuleRef(module).
	 */
	public static macro function moduleRef(moduleRefExpr:Expr):ExprOf<ChildSpecFormat> {
		var moduleName = elixir.otp.macros.ChildSpecModuleResolver.resolveModuleName(moduleRefExpr, "TypeSafeChildSpec.moduleRef",
			"TypeSafeChildSpec.moduleRefUnsafe");
		return macro TypeSafeChildSpec.moduleRefUnsafe($v{moduleName});
	}

	/**
	 * Dynamic escape hatch for ChildSpecFormat.ModuleRef(module).
	 */
	public static inline function moduleRefUnsafe(module:String):ChildSpecFormat {
		return ModuleRef(module);
	}

	/**
	 * Generic typed wrapper for ChildSpecFormat.ModuleWithConfig(module, config).
	 */
	public static macro function moduleWithConfig(moduleRefExpr:Expr, config:Expr):ExprOf<ChildSpecFormat> {
		var moduleName = elixir.otp.macros.ChildSpecModuleResolver.resolveModuleName(moduleRefExpr, "TypeSafeChildSpec.moduleWithConfig",
			"TypeSafeChildSpec.moduleWithConfigUnsafe");
		return macro TypeSafeChildSpec.moduleWithConfigUnsafe($v{moduleName}, $config);
	}

	/**
	 * Dynamic escape hatch for ChildSpecFormat.ModuleWithConfig(module, config).
	 */
	public static inline function moduleWithConfigUnsafe(module:String, config:Array<{key:String, value:Term}>):ChildSpecFormat {
		return ModuleWithConfig(module, config);
	}

	/**
	 * Generic typed wrapper for ChildSpecFormat.ModuleWithArgs(module, args).
	 */
	public static macro function moduleWithArgs(moduleRefExpr:Expr, args:Expr):ExprOf<ChildSpecFormat> {
		var moduleName = elixir.otp.macros.ChildSpecModuleResolver.resolveModuleName(moduleRefExpr, "TypeSafeChildSpec.moduleWithArgs",
			"TypeSafeChildSpec.moduleWithArgsUnsafe");
		return macro TypeSafeChildSpec.moduleWithArgsUnsafe($v{moduleName}, $args);
	}

	/**
	 * Dynamic escape hatch for ChildSpecFormat.ModuleWithArgs(module, args).
	 */
	public static inline function moduleWithArgsUnsafe(module:String, args:Array<Term>):ChildSpecFormat {
		return ModuleWithArgs(module, args);
	}

	/**
	 * Dynamic child specification from a map.
	 */
	public static inline function fromMap(spec:ChildSpec):ChildSpecFormat {
		return FullSpec(spec);
	}

	/**
	 * Create a simple child spec from module and arguments (typed module reference).
	 */
	public static macro function simple(moduleRef:Expr, ?args:Expr):ExprOf<ChildSpecFormat> {
		var moduleName = elixir.otp.macros.ChildSpecModuleResolver.resolveModuleName(moduleRef, "TypeSafeChildSpec.simple", "TypeSafeChildSpec.simpleUnsafe");
		var argsExpr = args != null ? args : macro null;
		return macro TypeSafeChildSpec.simpleUnsafe($v{moduleName}, $argsExpr);
	}

	/**
	 * Explicit dynamic escape hatch for simple child specs.
	 */
	public static inline function simpleUnsafe(module:String, ?args:Array<Term>):ChildSpecFormat {
		if (args != null && args.length > 0) {
			return ModuleWithArgs(module, args);
		}
		return ModuleRef(module);
	}
}
