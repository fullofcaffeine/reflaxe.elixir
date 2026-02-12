package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
#if macro
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import reflaxe.elixir.macros.RepoDiscovery;
#end

/**
 * HeexInlineMarkupConstStringRefsTransforms
 *
 * WHAT
 * - Rewrites brace-style attribute expressions in ~H content that reference Haxe string constants
 *   (e.g. `phx-hook={HookName.Ping}`) into literal binaries (e.g. `phx-hook={"Ping"}`).
 *
 * WHY
 * - Haxe inline markup literals (`return <div ...>...</div>`) are represented as a string with
 *   embedded brace expressions, but those expressions are *text*, not typed Haxe AST.
 * - For phx-hook/phx-* events we want TSX-level strictness (compile-time validation) and also
 *   valid runtime HEEx/Elixir output. Leaving `HookName.Ping` in the template would be invalid
 *   Elixir and would also fail strict checks (it is not a compile-time string literal).
 *
 * HOW
 * - Build a compile-time map from `TypeName.ConstName` → `"value"` for types annotated with
 *   `@:phxHookNames` and `@:phxEventNames`.
 * - Scan ~H sigil content for tag attributes written as `attr={...}` and, when the inner
 *   expression matches a known constant reference, replace it with a quoted string literal.
 *
 * EXAMPLES
 * Haxe (inline markup):
 *   return <button phx-click={EventName.Save} phx-hook={HookName.Ping}>Save</button>;
 *
 * Elixir (before):
 *   <button phx-click={EventName.Save} phx-hook={HookName.Ping}>Save</button>
 *
 * Elixir (after):
 *   <button phx-click={"save"} phx-hook={"Ping"}>Save</button>
 */
class HeexInlineMarkupConstStringRefsTransforms {
	#if macro
	static var constRefToValueCache:Null<Map<String, String>> = null;
	#end

	public static function transformPass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case ESigil(type, content, modifiers) if (type == "H" || type == "h"):
					var updated = rewriteHeexContent(content);
					if (updated != content) {
						var nextMeta = n.metadata;
						if (nextMeta != null) {
							nextMeta.heexAST = reflaxe.elixir.ast.builders.HeexAnalysisASTBuilder.build(updated);
						}
						makeASTWithMeta(ESigil(type, updated, modifiers), nextMeta, n.pos);
					} else {
						n;
					}
				default:
					n;
			}
		});
	}

	static function rewriteHeexContent(content:String):String {
		if (content == null)
			return content;
		if (content.indexOf("={") == -1)
			return content;

		inline function isWs(ch:String):Bool
			return ch != null && ~/^\\s$/.match(ch);

		function escapeElixirStringLiteral(s:String):String {
			if (s == null || s.length == 0)
				return "";
			var out = new StringBuf();
			for (i in 0...s.length) {
				var ch = s.charAt(i);
				switch (ch) {
					case "\\":
						out.add("\\\\");
					case "\"":
						out.add("\\\"");
					case "\n":
						out.add("\\n");
					case "\r":
						out.add("\\r");
					case "\t":
						out.add("\\t");
					default:
						out.add(ch);
				}
			}
			return out.toString();
		}

		#if macro
		var constRefToValue:Null<Map<String, String>> = null;
		#end

		var out = new StringBuf();
		var inTag = false;
		var index = 0;
		while (index < content.length) {
			var ch = content.charAt(index);
			if (!inTag) {
				if (ch == "<")
					inTag = true;
				out.add(ch);
				index++;
				continue;
			}

			if (ch == ">") {
				inTag = false;
				out.add(ch);
				index++;
				continue;
			}

			if (ch == "=") {
				out.add("=");
				var cursor = index + 1;
				while (cursor < content.length && isWs(content.charAt(cursor))) {
					out.add(content.charAt(cursor));
					cursor++;
				}

				if (cursor < content.length && content.charAt(cursor) == "{") {
					out.add("{");
					var exprStart = cursor + 1;
					cursor = exprStart;
					var depth = 1;
					var inS = false;
					var inD = false;
					while (cursor < content.length && depth > 0) {
						var cj = content.charAt(cursor);
						if (!inS && cj == "\"" && !inD) {
							inD = true;
							cursor++;
							continue;
						} else if (inD && cj == "\"") {
							inD = false;
							cursor++;
							continue;
						}
						if (!inD && cj == "'" && !inS) {
							inS = true;
							cursor++;
							continue;
						} else if (inS && cj == "'") {
							inS = false;
							cursor++;
							continue;
						}
						if (inS || inD) {
							cursor++;
							continue;
						}

						if (cj == "{")
							depth++;
						else if (cj == "}")
							depth--;
						cursor++;
					}

					if (depth != 0) {
						// Malformed; emit remainder as-is.
						out.add(content.substr(exprStart));
						break;
					}

					var exprEndExclusive = cursor - 1;
					var rawInner = content.substr(exprStart, exprEndExclusive - exprStart);
					var trimmed = StringTools.trim(rawInner);

					// Unwrap redundant parens.
					while (trimmed.length >= 2 && trimmed.charAt(0) == "(" && trimmed.charAt(trimmed.length - 1) == ")") {
						trimmed = StringTools.trim(trimmed.substr(1, trimmed.length - 2));
					}

					#if macro
					if (trimmed.indexOf(".") != -1 && trimmed.indexOf("@") == -1) {
						if (constRefToValue == null)
							constRefToValue = getConstRefToValueMap();
					}

					if (constRefToValue != null && constRefToValue.exists(trimmed)) {
						var value = constRefToValue.get(trimmed);
						out.add("\"");
						out.add(escapeElixirStringLiteral(value));
						out.add("\"");
					} else {
						out.add(rawInner);
					}
					#else
					out.add(rawInner);
					#end

					out.add("}");
					index = cursor;
					continue;
				}

				index = cursor;
				continue;
			}

			out.add(ch);
			index++;
		}

		return out.toString();
	}

	#if macro
	static function getConstRefToValueMap():Null<Map<String, String>> {
		if (constRefToValueCache != null)
			return constRefToValueCache;
		constRefToValueCache = buildConstRefToValueMap();
		return constRefToValueCache;
	}

	static function buildConstRefToValueMap():Null<Map<String, String>> {
		var map:Map<String, String> = new Map();

		var discovered = RepoDiscovery.getDiscovered();
		if (discovered == null || discovered.length == 0) {
			RepoDiscovery.run();
			discovered = RepoDiscovery.getDiscovered();
		}

		if (discovered == null || discovered.length == 0)
			return map;

		function addRef(typePath:String, typeName:String, fieldName:String, value:String):Void {
			if (typeName != null && fieldName != null)
				map.set(typeName + "." + fieldName, value);
			if (typePath != null && fieldName != null)
				map.set(typePath + "." + fieldName, value);
		}

		function extractStringConst(expr:Null<TypedExpr>):Null<String> {
			if (expr == null)
				return null;
			return switch (expr.expr) {
				case TConst(TString(s)):
					s;
				case TMeta(_, inner):
					extractStringConst(inner);
				case TCast(inner, _):
					extractStringConst(inner);
				case TParenthesis(inner):
					extractStringConst(inner);
				default:
					null;
			};
		}

		function collectStatics(typePath:String, typeName:String, cls:Null<haxe.macro.Type.ClassType>):Void {
			if (cls == null)
				return;
			for (field in cls.statics.get()) {
				if (field == null)
					continue;
				var value = extractStringConst(field.expr());
				if (value != null && value.length > 0)
					addRef(typePath, typeName, field.name, value);
			}
		}

		for (typePath in discovered) {
			if (typePath == null || typePath.length == 0)
				continue;
			var t:haxe.macro.Type = null;
			try
				t = Context.getType(typePath)
			catch (_:Dynamic)
				t = null;
			if (t == null)
				continue;

			var typeName = {
				var lastDot = typePath.lastIndexOf(".");
				lastDot == -1 ? typePath : typePath.substr(lastDot + 1);
			};

			switch (TypeTools.follow(t)) {
				case TAbstract(aRef, _):
					var abs = aRef.get();
					if (abs == null || abs.meta == null)
						continue;
					if (!abs.meta.has(":phxHookNames") && !abs.meta.has(":phxEventNames"))
						continue;
					collectStatics(typePath, typeName, abs.impl != null ? abs.impl.get() : null);
				case TInst(cRef, _):
					var cls = cRef.get();
					if (cls == null || cls.meta == null)
						continue;
					if (!cls.meta.has(":phxHookNames") && !cls.meta.has(":phxEventNames"))
						continue;
					collectStatics(typePath, typeName, cls);
				default:
			}
		}

		return map;
	}
	#end
}
#end
