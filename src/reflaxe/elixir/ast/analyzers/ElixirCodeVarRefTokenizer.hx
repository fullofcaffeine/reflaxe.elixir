package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)
/**
 * ElixirCodeVarRefTokenizer
 *
 * WHAT
 * - Extracts *likely local variable identifiers* from small snippets of Elixir source code.
 * - Used primarily to detect variables referenced inside interpolated strings (`"#{...}"`)
 *   where we don't have a structured ElixirAST representation for the interpolation body.
 *
 * WHY
 * - Several hygiene/repair passes (unused underscore, binder alignment, alias injection)
 *   must treat `n` as “used” in `"Got #{Kernel.to_string(n)}"` even though `n` does not
 *   appear as an `EVar("n")` node in the AST.
 * - Without this, downstream passes can incorrectly underscore/drop locals, producing
 *   undefined-variable errors under `--warnings-as-errors` (WAE) or at runtime.
 *
 * HOW
 * - A small tokenizer that:
 *   - Skips quoted strings (single and double) while still parsing nested interpolations.
 *   - Collects identifier tokens that *look like local vars* (lowercase or underscore-leading).
 *   - Filters out atoms (`:name`), keyword keys (`name:`), module attributes (`@name`),
 *     dotted field names (`obj.name`), and local function calls (`name(...)`).
 *
 * EXAMPLES
 * - `"Got #{Kernel.to_string(n)}"` → collects `n`
 * - `"#{:ok}"` → collects none
 * - `"#{inspect(value)}"` → collects `value` (not `inspect`)
 */
class ElixirCodeVarRefTokenizer {
	public static function collectFromInterpolatedStringText(text:String, out:Map<String, Bool>):Void {
		if (text == null || text.length == 0 || out == null)
			return;
		collectFromElixirCode(wrapAsDoubleQuotedStringLiteral(text), out);
	}

	public static function collectFromElixirCode(code:String, out:Map<String, Bool>):Void {
		if (code == null || code.length == 0 || out == null)
			return;

		inline function isIdentStart(ch:String):Bool {
			if (ch == null || ch.length == 0)
				return false;
			return (ch >= "A" && ch <= "Z") || (ch >= "a" && ch <= "z") || ch == "_";
		}

		inline function isIdentChar(ch:String):Bool {
			if (ch == null || ch.length == 0)
				return false;
			return (ch >= "A" && ch <= "Z") || (ch >= "a" && ch <= "z") || (ch >= "0" && ch <= "9") || ch == "_";
		}

		inline function isLowercaseVar(name:String):Bool {
			if (name == null || name.length == 0)
				return false;
			var c = name.charAt(0);
			if (c == "_")
				return true;
			return c.toLowerCase() == c && c.toUpperCase() != c;
		}

		function nextNonSpaceChar(pos:Int):String {
			var i = pos;
			while (i < code.length) {
				var ch = code.charAt(i);
				if (ch != " " && ch != "\t" && ch != "\n" && ch != "\r")
					return ch;
				i++;
			}
			return "";
		}

		function scanSingleQuotedString(startIdx:Int):Int {
			var i = startIdx;
			while (i < code.length) {
				var ch = code.charAt(i);
				if (ch == "\\") {
					i += 2;
					continue;
				}
				if (ch == "'")
					return i + 1;
				i++;
			}
			return code.length;
		}

		function scanDoubleQuotedString(startIdx:Int):Int {
			var i = startIdx;
			while (i < code.length) {
				var ch = code.charAt(i);
				if (ch == "\\") {
					i += 2;
					continue;
				}
				if (ch == "#" && i + 1 < code.length && code.charAt(i + 1) == "{") {
					var innerStart = i + 2;
					var depth = 1;
					var j = innerStart;
					while (j < code.length && depth > 0) {
						var cj = code.charAt(j);
						if (cj == "\\") {
							j += 2;
							continue;
						}
						if (cj == "'") {
							j = scanSingleQuotedString(j + 1);
							continue;
						}
						if (cj == "\"") {
							j = scanDoubleQuotedString(j + 1);
							continue;
						}
						if (cj == "{")
							depth++;
						else if (cj == "}")
							depth--;
						j++;
					}
					var innerEnd = (j > innerStart) ? (j - 1) : innerStart;
					if (innerEnd > innerStart)
						collectFromElixirCode(code.substr(innerStart, innerEnd - innerStart), out);
					i = j;
					continue;
				}
				if (ch == "\"")
					return i + 1;
				i++;
			}
			return code.length;
		}

		var i = 0;
		while (i < code.length) {
			var ch = code.charAt(i);

			if (ch == "\"") {
				i = scanDoubleQuotedString(i + 1);
				continue;
			}
			if (ch == "'") {
				i = scanSingleQuotedString(i + 1);
				continue;
			}

			if (!isIdentStart(ch)) {
				i++;
				continue;
			}

			var start = i;
			i++;
			while (i < code.length && isIdentChar(code.charAt(i)))
				i++;
			var name = code.substr(start, i - start);

			if (!isLowercaseVar(name))
				continue;

			var prev = start > 0 ? code.charAt(start - 1) : "";
			var prevPrev = start > 1 ? code.charAt(start - 2) : "";
			var next = i < code.length ? code.charAt(i) : "";
			var nextNext = i + 1 < code.length ? code.charAt(i + 1) : "";

			var isAtom = (prev == ":" && prevPrev != ":");
			var isKeywordKey = (next == ":" && nextNext != ":");
			var isAssign = (prev == "@");
			var isFieldName = (prev == ".");
			var isCall = (nextNonSpaceChar(i) == "(");

			if (isAtom || isKeywordKey || isAssign || isFieldName || isCall)
				continue;

			out.set(name, true);
		}
	}

	static function wrapAsDoubleQuotedStringLiteral(text:String):String {
		if (text == null)
			return "\"\"";
		var escaped = text.split("\\").join("\\\\").split("\"").join("\\\"");
		return "\"" + escaped + "\"";
	}
}
#end
