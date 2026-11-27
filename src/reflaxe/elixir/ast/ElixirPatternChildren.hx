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
	/**
	 * Rebuild a pattern after mapping each immediate structural child once.
	 *
	 * Returns `pattern` itself when every mapped child is the same object, and copies
	 * an array or record only when one of its entries changed. Children are mapped in
	 * deterministic field order.
	 */
	public static function mapImmediate(pattern:EPattern, mapAstChild:ElixirAST->ElixirAST, mapPatternChild:EPattern->EPattern):EPattern {
		if (pattern == null)
			return null;

		return switch (pattern) {
			case PVar(_):
				pattern;

			case PLiteral(value):
				var mapped = mapAstChild(value);
				mapped != value ? PLiteral(mapped) : pattern;

			case PTuple(elements):
				var mapped = mapPatterns(elements, mapPatternChild);
				mapped != elements ? PTuple(mapped) : pattern;

			case PList(elements):
				var mapped = mapPatterns(elements, mapPatternChild);
				mapped != elements ? PList(mapped) : pattern;

			case PCons(head, tail): var mappedHead = mapPatternChild(head); var mappedTail = mapPatternChild(tail); mappedHead != head || mappedTail != tail ? PCons(mappedHead,
					mappedTail) : pattern;

			case PMap(pairs):
				var mappedPairs = pairs;
				for (i in 0...pairs.length) {
					var pair = pairs[i];
					var key = mapAstChild(pair.key);
					var value = mapPatternChild(pair.value);
					if (key != pair.key || value != pair.value) {
						if (mappedPairs == pairs)
							mappedPairs = pairs.copy();
						mappedPairs[i] = {key: key, value: value};
					}
				}
				mappedPairs != pairs ? PMap(mappedPairs) : pattern;

			case PStruct(module, fields):
				var mappedFields = fields;
				for (i in 0...fields.length) {
					var field = fields[i];
					var value = mapPatternChild(field.value);
					if (value != field.value) {
						if (mappedFields == fields)
							mappedFields = fields.copy();
						mappedFields[i] = {key: field.key, value: value};
					}
				}
				mappedFields != fields ? PStruct(module, mappedFields) : pattern;

			case PPin(inner):
				var mapped = mapPatternChild(inner);
				mapped != inner ? PPin(mapped) : pattern;

			case PWildcard:
				pattern;

			case PAlias(varName, inner):
				var mapped = mapPatternChild(inner);
				mapped != inner ? PAlias(varName, mapped) : pattern;

			case PBinary(segments):
				var mappedSegments = segments;
				for (i in 0...segments.length) {
					var segment = segments[i];
					var segmentPattern = mapPatternChild(segment.pattern);
					var size = segment.size != null ? mapAstChild(segment.size) : null;
					if (segmentPattern != segment.pattern || size != segment.size) {
						if (mappedSegments == segments)
							mappedSegments = segments.copy();
						mappedSegments[i] = {
							pattern: segmentPattern,
							size: size,
							type: segment.type,
							modifiers: segment.modifiers
						};
					}
				}
				mappedSegments != segments ? PBinary(mappedSegments) : pattern;
		};
	}

	/** Maps each pattern; returns `patterns` itself unless an entry changed. */
	static function mapPatterns(patterns:Array<EPattern>, mapPatternChild:EPattern->EPattern):Array<EPattern> {
		var mapped = patterns;
		for (i in 0...patterns.length) {
			var original = patterns[i];
			var next = mapPatternChild(original);
			if (next != original) {
				if (mapped == patterns)
					mapped = patterns.copy();
				mapped[i] = next;
			}
		}
		return mapped;
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
		return switch (pattern) {
			case null | PVar(_) | PWildcard:
				pattern;
			default:
				function walkChild(child:EPattern):EPattern
					return mapImmediate(child, mapAst, walkChild);
				mapImmediate(pattern, mapAst, walkChild);
		};
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
