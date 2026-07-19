package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.ElixirAST;

/**
 * Exhaustive structural child contract for Elixir patterns.
 *
 * This module owns only immediate pattern and AST children. It does not decide
 * whether a pattern binds, reads, shadows, or introduces a lexical scope; those
 * semantics belong to scope-aware analyzers layered over this structural map.
 *
 * There is intentionally no catch-all case. Adding an `EPattern` constructor
 * must make this switch non-exhaustive until its child behavior is declared.
 */
class ElixirPatternChildren {
	/** Rebuild a pattern after mapping each immediate structural child once. */
	public static function mapImmediate(pattern:EPattern, mapAstChild:ElixirAST->ElixirAST, mapPatternChild:EPattern->EPattern):EPattern {
		if (pattern == null)
			return null;

		var changed = false;
		function mapAst(child:ElixirAST):ElixirAST {
			var mapped = mapAstChild(child);
			if (mapped != child)
				changed = true;
			return mapped;
		}
		function mapPattern(child:EPattern):EPattern {
			var mapped = mapPatternChild(child);
			if (mapped != child)
				changed = true;
			return mapped;
		}

		var mapped = switch (pattern) {
			case PVar(name):
				PVar(name);

			case PLiteral(value):
				PLiteral(mapAst(value));

			case PTuple(elements):
				PTuple(elements.map(mapPattern));

			case PList(elements):
				PList(elements.map(mapPattern));

			case PCons(head, tail):
				PCons(mapPattern(head), mapPattern(tail));

			case PMap(pairs):
				PMap(pairs.map(pair -> {
					key: mapAst(pair.key),
					value: mapPattern(pair.value)
				}));

			case PStruct(module, fields):
				PStruct(module, fields.map(field -> {
					key: field.key,
					value: mapPattern(field.value)
				}));

			case PPin(inner):
				PPin(mapPattern(inner));

			case PWildcard:
				PWildcard;

			case PAlias(varName, inner):
				PAlias(varName, mapPattern(inner));

			case PBinary(segments):
				PBinary(segments.map(segment -> {
					pattern: mapPattern(segment.pattern),
					size: segment.size != null ? mapAst(segment.size) : null,
					type: segment.type,
					modifiers: segment.modifiers
				}));
		};

		return changed ? mapped : pattern;
	}

	/** Visit each immediate AST and pattern child in deterministic field order. */
	public static function forEachImmediate(pattern:EPattern, visitAst:ElixirAST->Void, visitPattern:EPattern->Void):Void {
		mapImmediate(pattern, child -> {
			if (child != null)
				visitAst(child);
			return child;
		}, child -> {
			if (child != null)
				visitPattern(child);
			return child;
		});
	}

	/** Map every nested pattern plus every AST value carried by the pattern. */
	public static function mapTree(pattern:EPattern, mapAst:ElixirAST->ElixirAST):EPattern {
		return mapImmediate(pattern, mapAst, child -> mapTree(child, mapAst));
	}

	/** Walk every nested pattern and AST value in deterministic preorder. */
	public static function walk(pattern:EPattern, visitAst:ElixirAST->Void, ?visitPattern:EPattern->Void):Void {
		if (pattern == null)
			return;

		if (visitPattern != null)
			visitPattern(pattern);

		forEachImmediate(pattern, visitAst, child -> walk(child, visitAst, visitPattern));
	}
}
#end
