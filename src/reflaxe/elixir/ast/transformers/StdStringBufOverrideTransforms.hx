package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;

/**
 * StdStringBufOverrideTransforms
 *
 * WHAT
 * - Replaces the body of module `StringBuf` with a small native Elixir
 *   implementation. The buffer is a struct whose `parts` field holds iodata.
 *
 * WHY
 * - A Haxe program builds text with many small appends:
 *     var out = new StringBuf();
 *     while (...) out.addChar(code);
 *   Each append must cost the same, however large the buffer already is.
 *   The earlier body appended with `struct.parts ++ [str]`. `++` copies its
 *   whole left list, so N appends cost N squared: a 40 KB JSON string value
 *   took 3.9 s to read.
 * - iodata is the BEAM form for this job: a list that may hold binaries and
 *   other such lists. `[earlier, piece]` is a new two-element list that points
 *   at `earlier` and copies nothing. `IO.iodata_to_binary/1` joins all pieces
 *   in one pass, in order, when the program asks for the string.
 * - `addSub` cuts in codepoints, the unit of every Haxe String position on
 *   this target (docs/05-architecture/STRING_INDEX_UNITS.md). The earlier body
 *   walked graphemes and counted UTF-16 units, so it cut "\r\n" and emoji in
 *   the wrong place.
 *
 * HOW
 * - Detects module StringBuf and replaces its body with ERaw functions:
 *   defstruct parts: []
 *   new/0, add/2, add_char/2, get_length/1, to_string/1, and add_sub/4.
 * - `add_sub/4` calls `StringTools.haxe_substr/3`, which reuses the position
 *   index of a large string. It is emitted only when the compiled Haxe class
 *   still has `addSub` after dead-code elimination. That is also the condition
 *   under which the compiler emits the StringTools runtime, because the Haxe
 *   body of `addSub` calls `substr`. An unused `addSub` therefore never leaves
 *   a call to a module that was not generated.
 * - Receiver-return convention: `add`, `add_char` and `add_sub` return the
 *   updated struct, and call sites rebind the receiver
 *   (`ReceiverReturnConventions`).
 *
 * LIMITS
 * - `get_length/1` joins the pieces and counts codepoints on each call.
 * - A buffer is a persistent value. An alias made before an append does not
 *   see that append (managed references: haxe.elixir.codex-0yn.10.3.14).
 *
 * EXAMPLES
 * Haxe:
 *   var b = new StringBuf();
 *   b.add("hi");
 *   b.toString();
 * Elixir (after override):
 *   defstruct parts: []
 *   def add(struct, x), do: %{struct | parts: [struct.parts, stringified_x]}
 *   def to_string(struct), do: IO.iodata_to_binary(struct.parts)
 *
 * Tests: test/snapshot/regression/string_buf_linear_append (interpreter
 * results and an 800 KB time budget).
 */
class StdStringBufOverrideTransforms {
	public static function transformPass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EModule(name, attrs, body) if (name == "StringBuf"):
					var blk = bodyBlock(n.metadata, n.pos, definesFunction(body, "add_sub"));
					makeASTWithMeta(EModule(name, attrs, [blk]), n.metadata, n.pos);
				case EDefmodule(name, doBlock) if (name == "StringBuf"):
					makeASTWithMeta(EDefmodule(name, bodyBlock(n.metadata, n.pos, definesFunction([doBlock], "add_sub"))), n.metadata, n.pos);
				default:
					n;
			}
		});
	}

	/**
	 * True when the compiled Haxe class body still defines function `name`.
	 *
	 * Dead-code elimination removes an unused Haxe method before this pass
	 * runs, so the compiled body shows which optional functions the program
	 * can call.
	 */
	static function definesFunction(body:Array<ElixirAST>, name:String):Bool {
		var found = false;
		for (node in body) {
			if (node == null)
				continue;
			ElixirASTTransformer.transformNode(node, function(n:ElixirAST):ElixirAST {
				switch (n.def) {
					case EDef(defName, _, _, _) | EDefp(defName, _, _, _) if (defName == name):
						found = true;
					default:
				}
				return n;
			});
		}
		return found;
	}

	static function bodyBlock(meta:ElixirMetadata, pos:haxe.macro.Expr.Position, withAddSub:Bool):ElixirAST {
		var code = ("  # `parts` is iodata: each append wraps the earlier parts as `[earlier, piece]`,\n"
			+ "  # so it copies nothing. `to_string/1` joins the pieces once.\n"
			+ "  defstruct parts: []\n"
			+ "  def new() do\n"
			+ "    %__MODULE__{}\n"
			+ "  end\n"
			+ "  def add(struct, x) do\n"
			+ "    str = cond do\n"
			+ "      Kernel.is_nil(x) -> \"null\"\n"
			+ "      Kernel.is_binary(x) -> x\n"
			+ "      true -> inspect(x)\n"
			+ "    end\n"
			+ "    %{struct | parts: [struct.parts, str]}\n"
			+ "  end\n"
			+ "  def add_char(struct, c) do\n"
			+ "    %{struct | parts: [struct.parts, <<c::utf8>>]}\n"
			+ "  end\n"
			+ (withAddSub ? "  def add_sub(struct, s, pos, len) do\n"
				+ "    if Kernel.is_nil(s) do\n"
				+ "      struct\n"
				+ "    else\n"
				+ "      %{struct | parts: [struct.parts, StringTools.haxe_substr(s, pos, len)]}\n"
				+ "    end\n"
				+ "  end\n" : "")
			+ "  def get_length(struct) do\n"
			+ "    struct.parts |> IO.iodata_to_binary() |> String.codepoints() |> length()\n"
			+ "  end\n"
			+ "  def to_string(struct) do\n"
			+ "    IO.iodata_to_binary(struct.parts)\n"
			+ "  end\n");
		var raw = makeAST(ERaw(code));
		return makeASTWithMeta(EBlock([raw]), meta, pos);
	}
}
#end
