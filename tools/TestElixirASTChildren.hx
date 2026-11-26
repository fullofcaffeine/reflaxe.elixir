package tools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.ElixirAST as ElixirASTNode;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.emptyMetadata;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTShallowEquality;
import reflaxe.elixir.ast.ElixirASTStructuralDigest;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirPatternChildren;
import reflaxe.elixir.ast.naming.ElixirAtom;

private typedef NodeCase = {
	final name:String;
	final node:ElixirASTNode;
	final astChildren:Int;
	final patternChildren:Int;
}

/** Focused executable contract for exhaustive structural AST traversal. */
@:nullSafety(Off)
class TestElixirASTChildren {
	public static function run():Expr {
		var samples = testConstructorCoverageAndImmediateChildren();
		testWalkMatchesImmediateChildRecursion(samples);
		testPatternCoverageAndEmbeddedAst();
		testMetadataPositionAndAttributeSpans();
		testDeterministicStructuralWalk();
		testTransformerDelegatesToStructuralChildren();
		testTransformerPreservesUnchangedBranches();
		testTransformerBoundaryStopsRecursion();
		testCopyingCallbackKeepsIdentity(samples);
		testShallowEqualityRejectsRealChanges();

		Sys.println("ElixirAST child traversal contract passed");
		return macro null;
	}

	static function testConstructorCoverageAndImmediateChildren():Array<NodeCase> {
		var child = ast("child");
		var pattern = PVar("pattern");
		var nodes:Array<NodeCase> = [
			nodeCase("EModule", EModule("Sample", [{name: "attr", value: child}], [child]), 2, 0),
			nodeCase("EDefmodule", EDefmodule("Sample", child), 1, 0),
			nodeCase("EDef", EDef("run", [pattern], child, child), 2, 1),
			nodeCase("EDefp", EDefp("run", [pattern], child, child), 2, 1),
			nodeCase("EDefmacro", EDefmacro("run", [pattern], child, child), 2, 1),
			nodeCase("EDefmacrop", EDefmacrop("run", [pattern], child, child), 2, 1),
			nodeCase("ECase", ECase(child,
				[
					{
						pattern: pattern,
						guard: child,
						body: child
					}
				]),
				3, 1),
			nodeCase("ECond", ECond([{condition: child, body: child}]), 2, 0),
			nodeCase("EMatch", EMatch(pattern, child), 1, 1),
			nodeCase("EWith", EWith([{pattern: pattern, expr: child}], child, child), 3, 1),
			nodeCase("EIf", EIf(child, child, child), 3, 0),
			nodeCase("EUnless", EUnless(child, child, child), 3, 0),
			nodeCase("ETry", ETry(child, [
				{
					pattern: pattern,
					varName: "error",
					body: child
				}
			],
				[{kind: Error, pattern: pattern, body: child}], child, child),
				5, 2),
			nodeCase("ERaise", ERaise(child, child), 2, 0),
			nodeCase("EThrow", EThrow(child), 1, 0),
			nodeCase("EList", EList([child]), 1, 0),
			nodeCase("ECons", ECons(child, child), 2, 0),
			nodeCase("ETuple", ETuple([child]), 1, 0),
			nodeCase("EMap", EMap([
				{
					key: child,
					value: child
				}
			]),
				2, 0),
			nodeCase("EStruct", EStruct("Sample", [{key: "value", value: child}]), 1, 0),
			nodeCase("EStructUpdate", EStructUpdate(child, [{key: "value", value: child}]), 2, 0),
			nodeCase("EKeywordList", EKeywordList([{key: "value", value: child}]), 1, 0),
			nodeCase("EBitstring", EBitstring([
				{
					value: child,
					size: child,
					type: "integer",
					modifiers: ["signed"]
				}
			]),
				2, 0),
			nodeCase("ECall", ECall(child, "run", [child]), 2, 0),
			nodeCase("EMacroCall", EMacroCall("schema", [child], child), 2, 0),
			nodeCase("ERemoteCall", ERemoteCall(child, "run", [child]), 2, 0),
			nodeCase("EPipe", EPipe(child, child), 2, 0),
			nodeCase("EBinary", EBinary(Add, child, child), 2, 0),
			nodeCase("EUnary", EUnary(Negate, child), 1, 0),
			nodeCase("EField", EField(child, "value"), 1, 0),
			nodeCase("EAccess", EAccess(child, child), 2, 0),
			nodeCase("ERange", ERange(child, child, false, child), 3, 0),
			nodeCase("EReceiverEffect", EReceiverEffect({
				receiver: {varId: 1, name: "receiver"},
				operation: child,
				resultShape: UpdatedReceiver,
				valueProjection: ReceiverValue,
				writeback: Always
			}),
				1, 0),
			nodeCase("EAtom", EAtom(ElixirAtom.raw("ok")), 0, 0),
			nodeCase("EString", EString("value"), 0, 0),
			nodeCase("EStringLiteral", EStringLiteral("#{literal}"), 0, 0),
			nodeCase("EInteger", EInteger(1), 0, 0),
			nodeCase("EFloat", EFloat(1.5), 0, 0),
			nodeCase("EBoolean", EBoolean(true), 0, 0),
			nodeCase("ENil", ENil, 0, 0),
			nodeCase("ECharlist", ECharlist("value"), 0, 0),
			nodeCase("EVar", EVar("value"), 0, 0),
			nodeCase("EPin", EPin(child), 1, 0),
			nodeCase("EUnderscore", EUnderscore, 0, 0),
			nodeCase("EFor", EFor([
				{
					pattern: pattern,
					expr: child
				}
			],
				[child], child, child, true),
				4, 1),
			nodeCase("EFn", EFn([{args: [pattern], guard: child, body: child}]), 2, 1),
			nodeCase("ECapture", ECapture(child, 1), 1, 0),
			nodeCase("EAlias", EAlias("Sample", "Alias"), 0, 0),
			nodeCase("EImport", EImport("Sample", [
				{
					name: "run",
					arity: 1
				}
			],
				null, true),
				0, 0),
			nodeCase("EUse", EUse("Sample", [child]), 1, 0),
			nodeCase("ERequire", ERequire("Sample", "Alias"), 0, 0),
			nodeCase("EQuote", EQuote([child], child), 2, 0),
			nodeCase("EUnquote", EUnquote(child), 1, 0),
			nodeCase("EUnquoteSplicing", EUnquoteSplicing(child), 1, 0),
			nodeCase("EReceive", EReceive([
				{
					pattern: pattern,
					guard: child,
					body: child
				}
			],
				{timeout: child, body: child}),
				4, 1),
			nodeCase("ESend", ESend(child, child), 2, 0),
			nodeCase("EBlock", EBlock([child]), 1, 0),
			nodeCase("EParen", EParen(child), 1, 0),
			nodeCase("EDo", EDo([child]), 1, 0),
			nodeCase("EModuleAttribute", EModuleAttribute("value", child), 1, 0),
			nodeCase("EModuledoc", EModuledoc("docs"), 0, 0),
			nodeCase("EDoc", EDoc("docs"), 0, 0),
			nodeCase("ESpec", ESpec("run() :: :ok"), 0, 0),
			nodeCase("ETypeDef", ETypeDef("result", ":ok"), 0, 0),
			nodeCase("ESigil", ESigil("H", "<p>ok</p>", ""), 0, 0),
			nodeCase("ERaw", ERaw(":ok"), 0, 0),
			nodeCase("EAssign", EAssign("value"), 0, 0),
			nodeCase("EFragment", EFragment("div", [
				{
					name: "class",
					value: child
				}
			], [child]), 2, 0)
		];

		assertConstructorSet("ElixirASTDef", Type.getEnumConstructs(ElixirASTDef), nodes.map(node -> node.name));

		for (sample in nodes) {
			var astChildren = 0;
			ElixirASTTransformer.iterateAST(sample.node, _ -> astChildren++);

			assertEquals(sample.astChildren, astChildren, sample.name + " immediate AST child count");
			var digest = ElixirASTStructuralDigest.digest(sample.node);
			assertEquals(digest, ElixirASTStructuralDigest.digest(sample.node), sample.name + " structural digest determinism");
			assertTrue(ElixirASTTransformer.transformNode(sample.node, child -> child) == sample.node,
				sample.name + " no-op traversal preserves node identity");
		}
		return nodes;
	}

	/**
	 * `ASTUtils.walk` must visit the same nodes, in the same preorder, as the
	 * older recursion that called `iterateAST` on each node. Every constructor
	 * sample is nested in one module, and each leaf gets its own name, so a
	 * change of visit order or a missed child fails this check.
	 */
	static function testWalkMatchesImmediateChildRecursion(samples:Array<NodeCase>):Void {
		var counter = 0;
		var distinct = samples.map(sample -> ElixirASTTransformer.transformNode(sample.node, node -> switch (node.def) {
			case EVar(_): makeASTWithMeta(EVar("leaf_" + (counter++)), node.metadata, node.pos);
			default: node;
		}));
		var root = makeAST(EModule("Walk", [{name: "attr", value: ast("attr_value")}], [makeAST(EBlock(distinct)), makeAST(EDo(distinct))]));

		var expected:Array<ElixirASTNode> = [];
		referencePreorder(root, expected);
		var actual:Array<ElixirASTNode> = [];
		ASTUtils.walk(root, node -> actual.push(node));

		assertTrue(counter > samples.length, "walk fixture has distinct leaves");
		assertEquals(expected.length, actual.length, "walk visit count");
		for (i in 0...expected.length)
			assertTrue(expected[i] == actual[i], "walk visit " + i + " is the same node in the same order");
		var none = 0;
		ASTUtils.walk(null, _ -> none++);
		assertEquals(0, none, "walk ignores a null root");
	}

	static function referencePreorder(node:ElixirASTNode, out:Array<ElixirASTNode>):Void {
		if (node == null || node.def == null)
			return;
		out.push(node);
		ElixirASTTransformer.iterateAST(node, child -> referencePreorder(child, out));
	}

	static function testPatternCoverageAndEmbeddedAst():Void {
		var patterns:Array<{
			name:String,
			pattern:EPattern,
			astChildren:Int,
			patternChildren:Int
		}> = [
			{
				name: "PVar",
				pattern: PVar("value"),
				astChildren: 0,
				patternChildren: 0
			},
			{
				name: "PLiteral",
				pattern: PLiteral(ast("literal")),
				astChildren: 1,
				patternChildren: 0
			},
			{
				name: "PTuple",
				pattern: PTuple([PVar("value")]),
				astChildren: 0,
				patternChildren: 1
			},
			{
				name: "PList",
				pattern: PList([PVar("value")]),
				astChildren: 0,
				patternChildren: 1
			},
			{
				name: "PCons",
				pattern: PCons(PVar("head"), PVar("tail")),
				astChildren: 0,
				patternChildren: 2
			},
			{
				name: "PMap",
				pattern: PMap([{key: ast("map_key"), value: PVar("value")}]),
				astChildren: 1,
				patternChildren: 1
			},
			{
				name: "PStruct",
				pattern: PStruct("Sample", [{key: "value", value: PVar("value")}]),
				astChildren: 0,
				patternChildren: 1
			},
			{
				name: "PPin",
				pattern: PPin(PVar("value")),
				astChildren: 0,
				patternChildren: 1
			},
			{
				name: "PWildcard",
				pattern: PWildcard,
				astChildren: 0,
				patternChildren: 0
			},
			{
				name: "PAlias",
				pattern: PAlias("alias", PVar("value")),
				astChildren: 0,
				patternChildren: 1
			},
			{
				name: "PBinary",
				pattern: PBinary([
					{
						pattern: PVar("value"),
						size: ast("binary_size"),
						type: "integer",
						modifiers: ["signed"]
					}
				]),
				astChildren: 1,
				patternChildren: 1
			}
			];

		assertConstructorSet("EPattern", Type.getEnumConstructs(EPattern), patterns.map(sample -> sample.name));

		for (sample in patterns) {
			var astChildren = 0;
			var patternChildren = 0;
			ElixirPatternChildren.forEachImmediate(sample.pattern, _ -> astChildren++, _ -> patternChildren++);

			assertEquals(sample.astChildren, astChildren, sample.name + " immediate AST child count");
			assertEquals(sample.patternChildren, patternChildren, sample.name + " immediate pattern child count");
		}

		var composite = PTuple([
			PLiteral(ast("literal")),
			PMap([
				{
					key: ast("map_key"),
					value: PBinary([
						{
							pattern: PVar("value"),
							size: ast("binary_size"),
							type: "integer",
							modifiers: ["signed"]
						}
					])
				}
			])
		]);
		var mapped = ElixirPatternChildren.mapTree(composite, renameVar);
		var names:Array<String> = [];
		ElixirPatternChildren.walk(mapped, node -> collectVarName(node, names));

		assertStrings(["mapped_literal", "mapped_map_key", "mapped_binary_size"], names, "pattern-contained AST mapping");
	}

	static function testMetadataPositionAndAttributeSpans():Void {
		var metadata = emptyMetadata();
		var pos = Context.currentPos();
		var node = makeASTWithMeta(EModule("Sample", [
			{
				name: "data-value",
				value: ast("attribute"),
				nameSpanStart: 1,
				nameSpanEnd: 11,
				valueSpanStart: 12,
				valueSpanEnd: 21
			}
		], [ast("body")]), metadata, pos);
		var mapped = ElixirASTTransformer.transformAST(node, renameVar);

		assertTrue(mapped.metadata == metadata, "node metadata reference is preserved");
		assertTrue(mapped.pos == pos, "node source position is preserved");

		switch (mapped.def) {
			case EModule(_, [attribute], _):
				assertEquals(1, attribute.nameSpanStart, "attribute name span start");
				assertEquals(11, attribute.nameSpanEnd, "attribute name span end");
				assertEquals(12, attribute.valueSpanStart, "attribute value span start");
				assertEquals(21, attribute.valueSpanEnd, "attribute value span end");
			default:
				fail("identity test did not preserve EModule shape");
		}
	}

	static function testDeterministicStructuralWalk():Void {
		var node = makeAST(ECase(ast("target"), [
			{
				pattern: PMap([{key: ast("pattern_key"), value: PVar("value")}]),
				guard: ast("guard"),
				body: ast("body")
			}
		]));
		var names:Array<String> = [];
		ASTUtils.walk(node, child -> collectVarName(child, names));

		assertStrings(["target", "pattern_key", "guard", "body"], names, "structural preorder");
	}

	static function testTransformerDelegatesToStructuralChildren():Void {
		var raw = makeAST(ERaw("unparsed_target_code()"));
		var node = makeAST(EBlock([
			makeAST(EMatch(PLiteral(ast("pattern_literal")), ast("rhs"))),
			makeAST(EReceiverEffect({
				receiver: {varId: 1, name: "receiver"},
				operation: ast("operation"),
				resultShape: UpdatedReceiver,
				valueProjection: ReceiverValue,
				writeback: Always
			})),
			raw
		]));
		var sawRaw = false;
		var mapped = ElixirASTTransformer.transformNode(node, child -> {
			return switch (child.def) {
				case ERaw(_):
					sawRaw = true;
					child;
				case EVar(name):
					makeASTWithMeta(EVar("mapped_" + name), child.metadata, child.pos);
				default:
					child;
			};
		});
		var names:Array<String> = [];
		ASTUtils.walk(mapped, child -> collectVarName(child, names));

		assertStrings(["mapped_pattern_literal", "mapped_rhs", "mapped_operation"], names, "transformNode structural child delegation");
		assertTrue(!sawRaw, "transformNode keeps raw target injection opaque");
	}

	static function testTransformerPreservesUnchangedBranches():Void {
		var untouched = makeAST(ECall(ast("service"), "fetch", [ast("id")]));
		var changed = makeAST(ECall(ast("service"), "store", [ast("old_value")]));
		var node = makeAST(EBlock([untouched, changed]));

		var identity = ElixirASTTransformer.transformNode(node, child -> child);
		assertTrue(identity == node, "a no-op traversal preserves the root object");

		var mapped = ElixirASTTransformer.transformNode(node, child -> switch (child.def) {
			case EVar("old_value"): makeASTWithMeta(EVar("new_value"), child.metadata, child.pos);
			default: child;
		});
		assertTrue(mapped != node, "a changed descendant rebuilds its ancestor path");
		switch (mapped.def) {
			case EBlock([mappedUntouched, mappedChanged]):
				assertTrue(mappedUntouched == untouched, "an unrelated sibling keeps its identity");
				assertTrue(mappedChanged != changed, "the changed branch is rebuilt");
			default:
				fail("structural sharing test did not preserve the block shape");
		}
	}

	static function testTransformerBoundaryStopsRecursion():Void {
		var node = makeAST(EBlock([ast("outside"), makeAST(EFn([{args: [], guard: null, body: ast("inside")}]))]));
		var mapped = ElixirASTTransformer.transformNodeUntil(node, renameVar, child -> switch (child.def) {
			case EFn(_): true;
			default: false;
		});
		var names:Array<String> = [];
		ASTUtils.walk(mapped, child -> collectVarName(child, names));

		assertStrings(["mapped_outside", "inside"], names, "transformNodeUntil lexical boundary");
	}

	/**
	 * A pass callback that rebuilds each node with the same children, for example
	 * `makeASTWithMeta(EBlock(statements.copy()), n.metadata, n.pos)`, changes
	 * nothing. The engine must then return the input object for every constructor,
	 * and the parent must not be rebuilt either.
	 */
	static function testCopyingCallbackKeepsIdentity(samples:Array<NodeCase>):Void {
		for (sample in samples) {
			var node = makeAST(sample.node.def);
			var copies = 0;
			var root = makeAST(EBlock([node, ast("sibling")]));
			var result = ElixirASTTransformer.transformNode(root, child -> {
				var copy = shallowCopy(child);
				if (copy != child)
					copies++;
				return copy;
			});
			assertTrue(copies > 0, sample.name + " copying callback made copies");
			assertTrue(ElixirASTShallowEquality.sameNode(node, shallowCopy(node)), sample.name + " one-level copy is the same node");
			assertTrue(result == root, sample.name + " copying callback keeps the root object");
		}
	}

	/** A copy with any visible difference must still replace the original. */
	static function testShallowEqualityRejectsRealChanges():Void {
		var target = ast("target");
		var arg = ast("arg");
		var node = makeAST(ECall(target, "put", [arg]));
		assertTrue(ElixirASTShallowEquality.sameNode(node, makeASTWithMeta(ECall(target, "put", [arg]), node.metadata, node.pos)),
			"same call with a new argument array is a copy");
		assertTrue(!ElixirASTShallowEquality.sameNode(node, makeASTWithMeta(ECall(target, "push", [arg]), node.metadata, node.pos)),
			"a changed function name is a change");
		assertTrue(!ElixirASTShallowEquality.sameNode(node, makeASTWithMeta(ECall(target, "put", [ast("arg")]), node.metadata, node.pos)),
			"a new child object is a change");
		assertTrue(!ElixirASTShallowEquality.sameNode(node, makeASTWithMeta(ECall(target, "put", [arg, arg]), node.metadata, node.pos)),
			"an extra argument is a change");
		assertTrue(!ElixirASTShallowEquality.sameNode(node, makeAST(ECall(target, "put", [arg]))), "fresh metadata is a change");
		assertTrue(!ElixirASTShallowEquality.sameNode(node, makeASTWithMeta(ECall(target, "put", [arg]), {}, node.pos)),
			"a metadata record copied with equal values is a change");
		assertTrue(!ElixirASTShallowEquality.sameNode(node, makeASTWithMeta(EBlock([target]), node.metadata, node.pos)), "a new constructor is a change");
		var bare:ElixirASTNode = {def: EVar("x"), metadata: null, pos: null};
		assertTrue(!ElixirASTShallowEquality.sameNode(bare, {def: EVar("x"), metadata: null, pos: null}), "null metadata never matches");
		var attribute = {
			name: "class",
			value: ast("value"),
			nameSpanStart: 1,
			nameSpanEnd: 6
		};
		var fragment = makeAST(EFragment("div", [attribute], []));
		assertTrue(!ElixirASTShallowEquality.sameNode(fragment,
			makeASTWithMeta(EFragment("div", [{name: attribute.name, value: attribute.value}], []), fragment.metadata, fragment.pos)),
			"an attribute that drops its span is a change");

		var real = ElixirASTTransformer.transformNode(makeAST(EBlock([makeAST(EBlock([ast("old_value")]))])), child -> switch (child.def) {
			case EVar("old_value"): makeASTWithMeta(EVar("new_value"), child.metadata, child.pos);
			default: shallowCopy(child);
		});
		var names:Array<String> = [];
		ASTUtils.walk(real, child -> collectVarName(child, names));
		assertStrings(["new_value"], names, "a real change under copying ancestors survives");
	}

	/**
	 * Rebuilds one node with new arrays and new clause records but the same child
	 * objects, scalars, metadata object, and position.
	 */
	static function shallowCopy(node:ElixirASTNode):ElixirASTNode {
		var params = Type.enumParameters(node.def).map(copyParameter);
		var def = Type.createEnumIndex(ElixirASTDef, Type.enumIndex(node.def), params);
		return makeASTWithMeta(def, node.metadata, node.pos);
	}

	static function copyParameter(value:Dynamic):Dynamic {
		if (Std.isOfType(value, Array)) {
			var values:Array<Dynamic> = value;
			return values.map(copyRecord);
		}
		return copyRecord(value);
	}

	static function copyRecord(value:Dynamic):Dynamic {
		if (value == null || Type.typeof(value) != TObject || Reflect.hasField(value, "def"))
			return value;
		var copy:Dynamic = {};
		for (field in Reflect.fields(value)) {
			var fieldValue:Dynamic = Reflect.field(value, field);
			Reflect.setField(copy, field, Std.isOfType(fieldValue, Array) ? (fieldValue : Array<Dynamic>).copy() : fieldValue);
		}
		return copy;
	}

	static function nodeCase(name:String, def:ElixirASTDef, astChildren:Int, patternChildren:Int):NodeCase {
		return {
			name: name,
			node: makeAST(def),
			astChildren: astChildren,
			patternChildren: patternChildren
		};
	}

	static function ast(name:String):ElixirASTNode {
		return makeAST(EVar(name));
	}

	static function renameVar(node:ElixirASTNode):ElixirASTNode {
		return switch (node.def) {
			case EVar(name): makeASTWithMeta(EVar("mapped_" + name), node.metadata, node.pos);
			default: node;
		};
	}

	static function collectVarName(node:ElixirASTNode, names:Array<String>):Void {
		switch (node.def) {
			case EVar(name):
				names.push(name);
			default:
		}
	}

	static function assertConstructorSet(label:String, expected:Array<String>, actual:Array<String>):Void {
		expected.sort(Reflect.compare);
		actual.sort(Reflect.compare);
		assertStrings(expected, actual, label + " constructor coverage");
	}

	static function assertStrings(expected:Array<String>, actual:Array<String>, label:String):Void {
		assertEquals(expected.join(","), actual.join(","), label);
	}

	static function assertEquals(expected:Dynamic, actual:Dynamic, label:String):Void {
		if (expected != actual)
			fail(label + ': expected `${expected}`, got `${actual}`');
	}

	static function assertTrue(value:Bool, label:String):Void {
		if (!value)
			fail(label);
	}

	static function fail(message:String):Void {
		Context.fatalError("ElixirAST child traversal contract failed: " + message, Context.currentPos());
	}
}
#end
