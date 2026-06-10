package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * StdHaxeRuntimeOverrideTransforms
 *
 * WHAT
 * - Provides minimal target-native fallbacks for select Haxe std runtime modules.
 * - Primary runtime source-of-truth for iterators now lives in `std/haxe/iterators/*.cross.hx`.
 * - This pass keeps a narrow fallback for iterator modules only when generated output is
 *   incomplete (docs-only/no `new|has_next|next` functions).
 * - Always overrides `PosException` and `EReg` with known-safe runtime blocks.
 *
 * WHY
 * - Keep WAE (`--warnings-as-errors`) stable in CI even if an iterator module regresses to a stub.
 * - Avoid brittle, always-on iterator replacement now that stdlib modules provide canonical runtime.
 * - Preserve backward compatibility while narrowing transformer scope to true safety-net behavior.
 *
 * HOW
 * - For `ArrayIterator` and `MapKeyValueIterator`, inspect the module AST and verify that
 *   `new/1`, `has_next/1`, and `next/1` are present.
 * - If missing, inject fallback runtime blocks (same semantics as previous override).
 * - For `PosException` and `EReg`, replace module bodies with stable runtime implementations.
 *
 * See also: `docs/05-architecture/ITERATOR_RUNTIME_MODEL.md`.
 *
 * EXAMPLES
 * - Generated module has `new/has_next/next`: keep as-is.
 * - Generated module is docs-only: inject fallback runtime so CI and runtime remain valid.
 */
class StdHaxeRuntimeOverrideTransforms {
	static final REQUIRED_ITERATOR_FUNCTIONS = ["new", "has_next", "next"];

	public static function transformPass(ast:ElixirAST):ElixirAST {
		return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EDefmodule(name, doBlock):
					if (name == "ArrayIterator"
						&& !hasRequiredFunctions(doBlock,
							REQUIRED_ITERATOR_FUNCTIONS)) arrayIteratorDef(n) else if (name == "MapKeyValueIterator"
						&& !hasRequiredFunctions(doBlock,
							REQUIRED_ITERATOR_FUNCTIONS)) mapKeyValueIteratorDef(n) else if (name == "PosException") posExceptionDef(n) else
						if (name == "EReg") eRegDef(n) else n;
				case EModule(name, attrs, body):
					if (name == "ArrayIterator" && !hasRequiredFunctionsInBody(body, REQUIRED_ITERATOR_FUNCTIONS)) {
						var arrayIteratorBlockNode = arrayIteratorBlock(n.metadata, n.pos);
						makeASTWithMeta(EModule(name, attrs, [arrayIteratorBlockNode]), n.metadata, n.pos);
					} else if (name == "MapKeyValueIterator" && !hasRequiredFunctionsInBody(body, REQUIRED_ITERATOR_FUNCTIONS)) {
						var mapKeyValueIteratorBlockNode = mapKeyValueIteratorBlock(n.metadata, n.pos);
						makeASTWithMeta(EModule(name, attrs, [mapKeyValueIteratorBlockNode]), n.metadata, n.pos);
					} else if (name == "PosException") {
						var posExceptionBlockNode = posExceptionBlock(n.metadata, n.pos);
						makeASTWithMeta(EModule(name, attrs, [posExceptionBlockNode]), n.metadata, n.pos);
					} else if (name == "EReg") {
						var eRegBlockNode = eRegBlock(n.metadata, n.pos);
						makeASTWithMeta(EModule(name, attrs, [eRegBlockNode]), n.metadata, n.pos);
					} else n;
				default:
					n;
			}
		});
	}

	static function hasRequiredFunctions(moduleAst:ElixirAST, requiredNames:Array<String>):Bool {
		var found = new Map<String, Bool>();
		for (requiredName in requiredNames)
			found.set(requiredName, false);

		ElixirASTTransformer.transformNode(moduleAst, function(n:ElixirAST):ElixirAST {
			return switch (n.def) {
				case EDef(name, _, _, _):
					if (found.exists(name))
						found.set(name, true);
					n;
				case EDefp(name, _, _, _):
					if (found.exists(name))
						found.set(name, true);
					n;
				default:
					n;
			}
		});

		for (requiredName in requiredNames) {
			if (found.get(requiredName) != true)
				return false;
		}
		return true;
	}

	static function hasRequiredFunctionsInBody(body:Array<ElixirAST>, requiredNames:Array<String>):Bool {
		return hasRequiredFunctions(makeAST(EBlock(body)), requiredNames);
	}

	static inline function arrayIteratorDef(orig:ElixirAST):ElixirAST {
		return makeASTWithMeta(EDefmodule("ArrayIterator", arrayIteratorBlock(orig.metadata, orig.pos)), orig.metadata, orig.pos);
	}

	static inline function arrayIteratorBlock(meta:ElixirMetadata, pos:haxe.macro.Expr.Position):ElixirAST {
		var raw = makeAST(ERaw("  defstruct array: [], current: 0, ref: nil\n"
			+ "  def new(array), do: %__MODULE__{array: array, current: 0, ref: make_ref()}\n"
			+ "  defp state_key(ref), do: {__MODULE__, ref}\n"
			+ "  defp current_index(struct) do\n"
			+ "    if Kernel.is_nil(struct.ref), do: struct.current, else: Process.get(state_key(struct.ref), struct.current)\n"
			+ "  end\n"
			+ "  def has_next(struct), do: current_index(struct) < length(struct.array)\n"
			+ "  def next(struct) do\n"
			+ "    i = current_index(struct)\n"
			+ "    if not Kernel.is_nil(struct.ref), do: Process.put(state_key(struct.ref), i + 1)\n"
			+ "    Enum.at(struct.array, i)\n"
			+ "  end\n"));
		return makeASTWithMeta(EBlock([raw]), meta, pos);
	}

	static inline function mapKeyValueIteratorDef(orig:ElixirAST):ElixirAST {
		return makeASTWithMeta(EDefmodule("MapKeyValueIterator", mapKeyValueIteratorBlock(orig.metadata, orig.pos)), orig.metadata, orig.pos);
	}

	static inline function mapKeyValueIteratorBlock(meta:ElixirMetadata, pos:haxe.macro.Expr.Position):ElixirAST {
		var raw = makeAST(ERaw("  defstruct pairs: [], ref: nil\n"
			+ "  # MapKeyValueIterator is used for Haxe `for (k => v in map)`-style loops.\n"
			+ "  # Runtime contract:\n"
			+ "  # - Haxe `Map`/`StringMap`/`IntMap` values are plain Elixir maps (`%{}`) and are passed here directly.\n"
			+ "  # - Non-map `IMap` implementations (e.g. tree-backed maps) should pass a list of `{k,v}` pairs.\n"
			+ "  def new(map_or_pairs) do\n"
			+ "    normalize_pair = fn\n"
			+ "      {k, v} -> %{:key => k, :value => v}\n"
			+ "      %{key: _k, value: _v} = pair -> pair\n"
			+ "      other -> raise ArgumentError, message: \"expected IMap pair list entry, got: \" <> inspect(other)\n"
			+ "    end\n"
			+ "    pairs =\n"
			+ "      cond do\n"
			+ "        Kernel.is_list(map_or_pairs) -> Enum.map(map_or_pairs, normalize_pair)\n"
			+
			"        Kernel.is_map(map_or_pairs) and not Map.has_key?(map_or_pairs, :__struct__) and not Map.has_key?(map_or_pairs, :__reflaxe_class__) -> Enum.map(Map.to_list(map_or_pairs), normalize_pair)\n"
			+
			"        Kernel.is_map(map_or_pairs) -> raise ArgumentError, message: \"expected plain Elixir map or key/value pair list; custom IMap implementations must pass pre-normalized pairs\"\n"
			+ "        true -> raise ArgumentError, message: \"expected plain Elixir map or key/value pair list, got: \" <> inspect(map_or_pairs)\n"
			+ "      end\n"
			+ "    %__MODULE__{pairs: pairs, ref: make_ref()}\n"
			+ "  end\n"
			+ "  defp state_key(ref), do: {__MODULE__, ref}\n"
			+ "  defp current_index(struct), do: Process.get(state_key(struct.ref), 0)\n"
			+ "  def has_next(struct), do: current_index(struct) < length(struct.pairs)\n"
			+ "  def next(struct) do\n"
			+ "    i = current_index(struct)\n"
			+ "    Process.put(state_key(struct.ref), i + 1)\n"
			+ "    case Enum.at(struct.pairs, i) do\n"
			+ "      %{key: k, value: v} -> %{:key => k, :value => v}\n"
			+ "      {k, v} -> %{:key => k, :value => v}\n"
			+ "      other -> raise ArgumentError, message: \"expected normalized IMap pair, got: \" <> inspect(other)\n"
			+ "    end\n"
			+ "  end\n"));
		return makeASTWithMeta(EBlock([raw]), meta, pos);
	}

	static inline function posExceptionDef(orig:ElixirAST):ElixirAST {
		return makeASTWithMeta(EDefmodule("PosException", posExceptionBlock(orig.metadata, orig.pos)), orig.metadata, orig.pos);
	}

	static inline function posExceptionBlock(meta:ElixirMetadata, pos:haxe.macro.Expr.Position):ElixirAST {
		// Ensure `defexception [...]` includes the fields used by this override even if Haxe DCE
		// prunes them from the type surface (e.g., when PosException.toString() is eliminated).
		//
		// Without this, `%__MODULE__{..., pos_infos: ...}` can fail at Elixir compile-time with:
		//   ** (KeyError) key :pos_infos not found expanding struct: PosException.__struct__/1
		if (meta != null) {
			if (meta.instanceFields == null)
				meta.instanceFields = [];
			if (meta.instanceFields.indexOf("pos_infos") == -1) {
				meta.instanceFields.push("pos_infos");
				meta.instanceFields.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));
			}
		}
		var raw = makeAST(ERaw("  def new(message, previous, pos) do\n"
			+ "    pos_infos =\n"
			+ "      if Kernel.is_nil(pos) do\n"
			+ "        %{:fileName => \"(unknown)\", :lineNumber => 0, :className => \"(unknown)\", :methodName => \"(unknown)\"}\n"
			+ "      else\n"
			+ "        pos\n"
			+ "      end\n"
			+ "    %__MODULE__{message: message, previous: previous, native: nil, stack: [], pos_infos: pos_infos}\n"
			+ "  end\n"
			+
			"  def to_string(struct), do: \"#{Kernel.to_string(struct.message)} in #{struct.pos_infos.className}.#{struct.pos_infos.methodName} at #{struct.pos_infos.fileName}:#{struct.pos_infos.lineNumber}\"\n"));
		return makeASTWithMeta(EBlock([raw]), meta, pos);
	}

	static inline function eRegDef(orig:ElixirAST):ElixirAST {
		return makeASTWithMeta(EDefmodule("EReg", eRegBlock(orig.metadata, orig.pos)), orig.metadata, orig.pos);
	}

	static inline function eRegBlock(meta:ElixirMetadata, pos:haxe.macro.Expr.Position):ElixirAST {
		var raw = makeAST(ERaw("  defstruct regex: nil, global: false, cap_count: 0, ref: nil\n"
			+ "  def new(pattern, options) do\n"
			+ "    opts = if Kernel.is_nil(options), do: \"\", else: options\n"
			+ "    global = String.contains?(opts, \"g\")\n"
			+ "    compile_opts = String.replace(opts, \"g\", \"\")\n"
			+ "    regex = Regex.compile!(pattern, compile_opts)\n"
			+ "    cap_count = elem(regex.re_pattern, 1)\n"
			+ "    %__MODULE__{regex: regex, global: global, cap_count: cap_count, ref: make_ref()}\n"
			+ "  end\n"
			+ "  def match(struct, s), do: match_sub(struct, s, 0, -1)\n"
			+ "  def match_sub(struct, s, pos, len \\\\ -1) do\n"
			+ "    subject = s\n"
			+ "    pos_g = max(pos, 0)\n"
			+ "    len_g = len\n"
			+ "    total_g = String.length(subject)\n"
			+ "    pos_g = if pos_g > total_g, do: total_g, else: pos_g\n"
			+ "    end_g = if len_g < 0, do: total_g, else: min(pos_g + len_g, total_g)\n"
			+ "    prefix = String.slice(subject, 0, end_g)\n"
			+ "    offset_b = byte_size(String.slice(subject, 0, pos_g))\n"
			+ "    indices = Regex.run(struct.regex, prefix, [return: :index, offset: offset_b])\n"
			+ "    if indices == nil do\n"
			+ "      Process.delete({:reflaxe_ereg, struct.ref})\n"
			+ "      false\n"
			+ "    else\n"
			+ "      expected = struct.cap_count + 1\n"
			+ "      missing = expected - length(indices)\n"
			+ "      pad = if missing > 0, do: List.duplicate({-1, 0}, missing), else: []\n"
			+ "      padded = indices ++ pad\n"
			+ "      [{mpos_b, mlen_b} | _] = padded\n"
			+ "      mpos_g = if mpos_b < 0, do: -1, else: String.length(binary_part(subject, 0, mpos_b))\n"
			+ "      mlen_g = if mpos_b < 0, do: 0, else: String.length(binary_part(subject, mpos_b, mlen_b))\n"
			+ "      matches =\n"
			+ "        Enum.map(padded, fn\n"
			+ "          {p, l} when is_integer(p) and p >= 0 -> binary_part(subject, p, l)\n"
			+ "          _ -> nil\n"
			+ "        end)\n"
			+ "      Process.put({:reflaxe_ereg, struct.ref}, %{subject: subject, matches: matches, pos: mpos_g, len: mlen_g})\n"
			+ "      true\n"
			+ "    end\n"
			+ "  end\n"
			+ "  def matched(struct, n) do\n"
			+ "    state = Process.get({:reflaxe_ereg, struct.ref})\n"
			+ "    if state == nil, do: haxe_throw(\"EReg::matched\")\n"
			+ "    matches = state.matches\n"
			+ "    if n >= 0 and n < length(matches), do: Enum.at(matches, n), else: haxe_throw(\"EReg::matched\")\n"
			+ "  end\n"
			+ "  def matched_left(struct) do\n"
			+ "    state = Process.get({:reflaxe_ereg, struct.ref})\n"
			+ "    if state == nil, do: haxe_throw(\"No string matched\")\n"
			+ "    String.slice(state.subject, 0, state.pos)\n"
			+ "  end\n"
			+ "  def matched_right(struct) do\n"
			+ "    state = Process.get({:reflaxe_ereg, struct.ref})\n"
			+ "    if state == nil, do: haxe_throw(\"No string matched\")\n"
			+ "    start = state.pos + state.len\n"
			+ "    String.slice(state.subject, start, String.length(state.subject) - start)\n"
			+ "  end\n"
			+ "  def matched_pos(struct) do\n"
			+ "    state = Process.get({:reflaxe_ereg, struct.ref})\n"
			+ "    if state == nil, do: haxe_throw(\"No string matched\")\n"
			+ "    %{pos: state.pos, len: state.len}\n"
			+ "  end\n"
			+ "  def split(struct, s) do\n"
			+ "    if struct.global do\n"
			+ "      Regex.split(struct.regex, s)\n"
			+ "    else\n"
			+ "      Regex.split(struct.regex, s, parts: 2)\n"
			+ "    end\n"
			+ "  end\n"
			+ "  def replace(struct, s, by) do\n"
			+ "    parts = String.split(by, \"$\", trim: false)\n"
			+ "    buf = replace_loop(struct, s, parts, 0, String.length(s), true, [])\n"
			+ "    IO.iodata_to_binary(buf)\n"
			+ "  end\n"
			+ "  defp replace_loop(struct, s, parts, pos, len, first, buf) do\n"
			+ "    if not match_sub(struct, s, pos, len) do\n"
			+ "      [buf, String.slice(s, pos, len)]\n"
			+ "    else\n"
			+ "      %{pos: mpos, len: mlen} = matched_pos(struct)\n"
			+ "      {mpos, done} =\n"
			+ "        cond do\n"
			+ "          mlen == 0 and not first and mpos == String.length(s) -> {mpos, true}\n"
			+ "          mlen == 0 and not first -> {mpos + 1, false}\n"
			+ "          true -> {mpos, false}\n"
			+ "        end\n"
			+ "      if done do\n"
			+ "        [buf, String.slice(s, pos, len)]\n"
			+ "      else\n"
			+ "        buf = [buf, String.slice(s, pos, mpos - pos), build_replacement(struct, parts)]\n"
			+ "        tot = mpos + mlen - pos\n"
			+ "        pos = pos + tot\n"
			+ "        len = len - tot\n"
			+ "        if struct.global, do: replace_loop(struct, s, parts, pos, len, false, buf), else: [buf, String.slice(s, pos, len)]\n"
			+ "      end\n"
			+ "    end\n"
			+ "  end\n"
			+ "  defp build_replacement(struct, parts) do\n"
			+ "    case parts do\n"
			+ "      [] -> \"\"\n"
			+ "      [head | tail] ->\n"
			+ "        state = Process.get({:reflaxe_ereg, struct.ref})\n"
			+ "        matches = if state == nil, do: [], else: state.matches\n"
			+ "        build_replace_tail(struct, matches, tail, [head])\n"
			+ "    end\n"
			+ "  end\n"
			+ "  defp build_replace_tail(_struct, _matches, [], acc), do: acc\n"
			+ "  defp build_replace_tail(struct, matches, [k | rest], acc) do\n"
			+ "    if k == \"\" do\n"
			+ "      case rest do\n"
			+ "        [] -> build_replace_tail(struct, matches, [], [acc, \"$\"])\n"
			+ "        [next | rest2] ->\n"
			+ "          acc2 = if next == \"\", do: [acc, \"$\"], else: [acc, \"$\", next]\n"
			+ "          build_replace_tail(struct, matches, rest2, acc2)\n"
			+ "      end\n"
			+ "    else\n"
			+ "      <<c, tail::binary>> = k\n"
			+ "      if c >= ?1 and c <= ?9 do\n"
			+ "        group_index = c - ?0\n"
			+ "        if group_index > struct.cap_count do\n"
			+ "          build_replace_tail(struct, matches, rest, [acc, \"$\", k])\n"
			+ "        else\n"
			+ "          capture = Enum.at(matches, group_index)\n"
			+ "          acc2 = if capture == nil, do: [acc, tail], else: [acc, capture, tail]\n"
			+ "          build_replace_tail(struct, matches, rest, acc2)\n"
			+ "        end\n"
			+ "      else\n"
			+ "        build_replace_tail(struct, matches, rest, [acc, \"$\", k])\n"
			+ "      end\n"
			+ "    end\n"
			+ "  end\n"
			+ "  def map(struct, s, f) do\n"
			+ "    total = String.length(s)\n"
			+ "    {buf, offset} = map_loop(struct, s, f, 0, total, [])\n"
			+ "    buf = if not struct.global and offset > 0 and offset < total, do: [buf, String.slice(s, offset, total - offset)], else: buf\n"
			+ "    IO.iodata_to_binary(buf)\n"
			+ "  end\n"
			+ "  defp map_loop(struct, s, f, offset, total, buf) do\n"
			+ "    cond do\n"
			+ "      offset >= total -> {buf, offset}\n"
			+ "      not match_sub(struct, s, offset, -1) -> {[buf, String.slice(s, offset, total - offset)], total}\n"
			+ "      true ->\n"
			+ "        %{pos: mpos, len: mlen} = matched_pos(struct)\n"
			+ "        buf = [buf, String.slice(s, offset, mpos - offset), f.(struct)]\n"
			+ "        {buf, new_offset} =\n"
			+ "          if mlen == 0 do\n"
			+ "            {[buf, String.slice(s, mpos, 1)], mpos + 1}\n"
			+ "          else\n"
			+ "            {buf, mpos + mlen}\n"
			+ "          end\n"
			+ "        if struct.global, do: map_loop(struct, s, f, new_offset, total, buf), else: {buf, new_offset}\n"
			+ "    end\n"
			+ "  end\n"
			+ "  def escape(s), do: Regex.escape(s)\n"
			+ "  defp haxe_throw(value), do: raise(Reflaxe.Elixir.HaxeThrow, [value: value])\n"));
		return makeASTWithMeta(EBlock([raw]), meta, pos);
	}

	// Reflect and Type overrides were transitional. They now live in std/*.cross.hx
	// and are gated via target-conditional classpath injection.
}
#end
