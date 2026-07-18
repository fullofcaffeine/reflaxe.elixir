package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

/** Typed configuration extracted from `@:mixTask` before target AST construction. */
typedef MixTaskConfig = {
	var shortdoc:Null<String>;
	var requirements:Array<String>;
	var moduledoc:Null<String>;
}

/**
 * Parses and validates the optional Haxe-facing Mix task declaration.
 *
 * WHAT
 * - Converts `@:mixTask({shortdoc: "...", requirements: ["app.config"]})`
 *   into typed compiler metadata.
 * - Requires the annotated class to expose `public static run(Array<String>)`.
 *
 * WHY
 * - Mix tasks need target-level declarations (`use Mix.Task`, module attributes,
 *   and the `run/1` callback) that ordinary Haxe class syntax cannot describe.
 * - Validation must happen while Haxe types and source positions are still
 *   available; late target-shape guesses would produce weak diagnostics.
 *
 * HOW
 * - Accepts either bare `@:mixTask` or one object-literal configuration.
 * - Rejects unknown keys and non-literal values instead of silently widening.
 * - Reads the class doc comment as the generated module documentation.
 *
 * EXAMPLE
 * ```haxe
 * /** Checks the generated application. *\/
 * @:mixTask({shortdoc: "Checks the app", requirements: ["app.config"]})
 * @:native("Mix.Tasks.Haxe.Check")
 * class CheckTask {
 *   public static function run(args:Array<String>):Void {}
 * }
 * ```
 */
class MixTaskMetadata {
	public static function read(classType:ClassType):Null<MixTaskConfig> {
		var entries = classType.meta.extract(":mixTask");
		if (entries.length == 0)
			return null;
		if (entries.length > 1)
			Context.error("Declare @:mixTask only once per class", entries[1].pos);

		validateTargetModule(classType, entries[0].pos);
		validateRunCallback(classType, entries[0].pos);

		var shortdoc:Null<String> = null;
		var requirements:Array<String> = [];
		var params = entries[0].params;
		if (params != null && params.length > 1)
			Context.error('@:mixTask accepts at most one options object: @:mixTask({shortdoc: "...", requirements: ["app.config"]})', entries[0].pos);

		if (params != null && params.length == 1) {
			switch (params[0].expr) {
				case EObjectDecl(fields):
					for (field in fields) {
						switch (field.field) {
							case "shortdoc":
								shortdoc = requireNonEmptyString(field.expr, "shortdoc");
							case "requirements":
								requirements = requireStringArray(field.expr, "requirements");
							default:
								Context.error('Unknown @:mixTask option "${field.field}". Supported options are shortdoc and requirements.', field.expr.pos);
						}
					}
				default:
					Context.error('@:mixTask options must be an object literal: @:mixTask({shortdoc: "...", requirements: ["app.config"]})', params[0].pos);
			}
		}

		var moduledoc = classType.doc == null ? null : normalizeDocumentation(classType.doc);
		if (moduledoc != null && moduledoc.length == 0)
			moduledoc = null;

		return {
			shortdoc: shortdoc,
			requirements: requirements,
			moduledoc: moduledoc
		};
	}

	static function validateTargetModule(classType:ClassType, annotationPos:Position):Void {
		var nativeEntries = classType.meta.extract(":native");
		if (nativeEntries.length != 1 || nativeEntries[0].params == null || nativeEntries[0].params.length != 1)
			Context.error('@:mixTask requires @:native("Mix.Tasks.Your.Task") so Mix can discover the generated module', annotationPos);

		var targetModule = switch (nativeEntries[0].params[0].expr) {
			case EConst(CString(value, _)): value;
			default:
				Context.error('@:mixTask @:native must contain a literal Mix.Tasks.* module name', nativeEntries[0].params[0].pos);
				"";
		};
		if (!targetModule.startsWith("Mix.Tasks.") || targetModule.length == "Mix.Tasks.".length)
			Context.error('@:mixTask target module must start with Mix.Tasks., found "${targetModule}"', nativeEntries[0].params[0].pos);
	}

	static function validateRunCallback(classType:ClassType, annotationPos:Position):Void {
		var runField:Null<ClassField> = null;
		for (field in classType.statics.get()) {
			if (field.name == "run") {
				runField = field;
				break;
			}
		}

		if (runField == null)
			Context.error("@:mixTask requires public static function run(args:Array<String>)", annotationPos);
		if (!runField.isPublic)
			Context.error("@:mixTask run must be public", runField.pos);

		switch (Context.follow(runField.type)) {
			case TFun(args, _) if (args.length == 1 && isStringArray(args[0].t)):
				return;
			default:
				Context.error("@:mixTask run must accept exactly one Array<String> argument", runField.pos);
		}
	}

	static function isStringArray(type:Type):Bool {
		return switch (Context.follow(type)) {
			case TInst(arrayRef, [elementType]): var arrayType = arrayRef.get(); arrayType.pack.length == 0 && arrayType.name == "Array" && isString(elementType);
			default:
				false;
		};
	}

	static function isString(type:Type):Bool {
		return switch (Context.follow(type)) {
			case TInst(stringRef, _): var stringType = stringRef.get(); stringType.pack.length == 0 && stringType.name == "String";
			default:
				false;
		};
	}

	static function requireNonEmptyString(expr:Expr, fieldName:String):String {
		return switch (expr.expr) {
			case EConst(CString(value, _)) if (value.trim().length > 0):
				value;
			default:
				Context.error('@:mixTask ${fieldName} must be a non-empty string literal', expr.pos);
				"";
		};
	}

	static function requireStringArray(expr:Expr, fieldName:String):Array<String> {
		return switch (expr.expr) {
			case EArrayDecl(values):
				var result:Array<String> = [];
				var seen = new Map<String, Bool>();
				for (valueExpr in values) {
					var value = requireNonEmptyString(valueExpr, fieldName);
					if (seen.exists(value))
						Context.error('@:mixTask ${fieldName} contains duplicate value "${value}"', valueExpr.pos);
					seen.set(value, true);
					result.push(value);
				}
				result;
			default:
				Context.error('@:mixTask ${fieldName} must be an array of string literals', expr.pos);
				[];
		};
	}

	/** Removes Haxe doc-comment margin markers while retaining intentional content. */
	static function normalizeDocumentation(documentation:String):String {
		var lines = documentation.replace("\r\n", "\n").split("\n");
		var normalized:Array<String> = [];
		for (line in lines) {
			var leftTrimmed = line.ltrim();
			if (leftTrimmed.startsWith("*")) {
				leftTrimmed = leftTrimmed.substr(1);
				if (leftTrimmed.startsWith(" "))
					leftTrimmed = leftTrimmed.substr(1);
				normalized.push(leftTrimmed.rtrim());
			} else {
				normalized.push(line.rtrim());
			}
		}
		while (normalized.length > 0 && normalized[0].trim().length == 0)
			normalized.shift();
		while (normalized.length > 0 && normalized[normalized.length - 1].trim().length == 0)
			normalized.pop();
		return normalized.join("\n");
	}
}
#end
