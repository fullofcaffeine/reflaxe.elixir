package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * Lowers typed `@:mixTask` metadata to ordinary, idiomatic Mix task declarations.
 *
 * WHAT
 * - Adds `use Mix.Task`, optional `@shortdoc`/`@requirements`, class
 *   documentation, and `@impl Mix.Task` before the typed `run/1` callback.
 *
 * WHY
 * - These are compile-time module declarations rather than runtime function
 *   calls, so externs alone cannot express them.
 * - A structured AST pass keeps the feature generic and avoids raw Elixir text
 *   or task-name/path heuristics.
 *
 * HOW
 * - Runs only when `ElixirMetadata.isMixTask` was set from the Haxe annotation.
 * - Decorates both module AST shapes and preserves every user-authored function.
 * - Detects existing exact directives so the transform is idempotent.
 *
 * EXAMPLE
 * - `@:mixTask ... class CheckTask { static function run(args) ... }` becomes
 *   a normal `defmodule` using `Mix.Task` with an annotated `def run(args)`.
 */
@:nullSafety(Off)
class MixTaskTransforms {
	public static function transformPass(ast:ElixirAST):ElixirAST {
		if (ast == null || ast.metadata?.isMixTask != true)
			return ast;

		return switch (ast.def) {
			case EModule(name, attributes, body):
				makeASTWithMeta(EModule(name, attributes, decorateBody(body, ast.metadata)), ast.metadata, ast.pos);
			case EDefmodule(name, body):
				var statements = switch (body.def) {
					case EBlock(values) | EDo(values): values;
					case ENil: [];
					default: [body];
				};
				makeASTWithMeta(EDefmodule(name, makeAST(EBlock(decorateBody(statements, ast.metadata)))), ast.metadata, ast.pos);
			default:
				ast;
		};
	}

	static function decorateBody(body:Array<ElixirAST>, metadata:ElixirMetadata):Array<ElixirAST> {
		var result:Array<ElixirAST> = [];
		var hasModuledoc = containsModuledoc(body);
		var hasUse = containsMixTaskUse(body);
		var hasShortdoc = containsAttribute(body, "shortdoc");
		var hasRequirements = containsAttribute(body, "requirements");
		var hasImpl = containsMixTaskImpl(body);

		var emitsModuledoc = !hasModuledoc && metadata.mixTaskModuledoc != null && metadata.mixTaskModuledoc.length > 0;
		if (emitsModuledoc)
			result.push(makeAST(EModuledoc(metadata.mixTaskModuledoc)));
		if (!hasUse)
			result.push(makeSeparatedAST(EUse("Mix.Task", []), emitsModuledoc || hasModuledoc));
		if (!hasShortdoc && metadata.mixTaskShortdoc != null && metadata.mixTaskShortdoc.length > 0)
			result.push(makeSeparatedAST(EModuleAttribute("shortdoc", makeAST(EString(metadata.mixTaskShortdoc))), true));
		if (!hasRequirements && metadata.mixTaskRequirements != null && metadata.mixTaskRequirements.length > 0) {
			var requirements = [for (requirement in metadata.mixTaskRequirements) makeAST(EString(requirement))];
			result.push(makeAST(EModuleAttribute("requirements", makeAST(EList(requirements)))));
		}

		for (statement in body) {
			if (!hasImpl && isRunDefinition(statement)) {
				result.push(makeSeparatedAST(EModuleAttribute("impl", makeAST(EVar("Mix.Task"))), true));
				hasImpl = true;
			}
			result.push(statement);
		}
		return result;
	}

	static function makeSeparatedAST(definition:ElixirASTDef, separated:Bool):ElixirAST {
		return separated ? makeASTWithMeta(definition, {blankLineBefore: true}) : makeAST(definition);
	}

	static function isRunDefinition(statement:ElixirAST):Bool {
		return switch (statement.def) {
			case EDef("run", args, _, _) if (args.length == 1): true;
			default: false;
		};
	}

	static function containsModuledoc(body:Array<ElixirAST>):Bool {
		for (statement in body)
			if (switch (statement.def) {
					case EModuledoc(_): true;
					default: false;
				})
				return true;
		return false;
	}

	static function containsMixTaskUse(body:Array<ElixirAST>):Bool {
		for (statement in body)
			if (switch (statement.def) {
					case EUse("Mix.Task", _): true;
					default: false;
				})
				return true;
		return false;
	}

	static function containsAttribute(body:Array<ElixirAST>, name:String):Bool {
		for (statement in body)
			if (switch (statement.def) {
					case EModuleAttribute(attributeName, _) if (attributeName == name): true;
					default: false;
				})
				return true;
		return false;
	}

	static function containsMixTaskImpl(body:Array<ElixirAST>):Bool {
		for (statement in body)
			if (switch (statement.def) {
					case EModuleAttribute("impl", {def: EVar("Mix.Task")}): true;
					default: false;
				})
				return true;
		return false;
	}
}
#end
