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
import reflaxe.elixir.ast.ElixirASTChildren;
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
		testConstructorCoverageAndImmediateChildren();
		testPatternCoverageAndEmbeddedAst();
		testMetadataPositionAndAttributeSpans();
		testIdentityMappingPreservesReferences();
		testDeterministicStructuralWalk();
		testTransformerDelegatesToStructuralChildren();
		testTransformerBoundaryStopsRecursion();

		Sys.println("ElixirAST child traversal contract passed");
		return macro null;
	}

	static function testConstructorCoverageAndImmediateChildren():Void {
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
			var patternChildren = 0;
			ElixirASTChildren.forEachImmediate(sample.node, _ -> astChildren++, _ -> patternChildren++);

			assertEquals(sample.astChildren, astChildren, sample.name + " immediate AST child count");
			assertEquals(sample.patternChildren, patternChildren, sample.name + " immediate pattern child count");
		}
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
		var mapped = ElixirASTChildren.mapImmediate(node, renameVar, pattern -> pattern);

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

	static function testIdentityMappingPreservesReferences():Void {
		var pattern = PTuple([PVar("value")]);
		var node = makeAST(ECase(ast("target"), [{pattern: pattern, guard: null, body: ast("body")}]));

		var mappedNode = ElixirASTChildren.mapImmediate(node, child -> child, child -> child);
		var mappedPattern = ElixirPatternChildren.mapImmediate(pattern, child -> child, child -> child);

		assertTrue(mappedNode == node, "identity AST mapping preserves the original node reference");
		assertTrue(mappedPattern == pattern, "identity pattern mapping preserves the original pattern reference");
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
		ElixirASTChildren.walk(node, child -> collectVarName(child, names));

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
		ElixirASTChildren.walk(mapped, child -> collectVarName(child, names));

		assertStrings(["mapped_pattern_literal", "mapped_rhs", "mapped_operation"], names, "transformNode structural child delegation");
		assertTrue(!sawRaw, "transformNode keeps raw target injection opaque");
	}

	static function testTransformerBoundaryStopsRecursion():Void {
		var node = makeAST(EBlock([ast("outside"), makeAST(EFn([{args: [], guard: null, body: ast("inside")}]))]));
		var mapped = ElixirASTTransformer.transformNodeUntil(node, renameVar, child -> switch (child.def) {
			case EFn(_): true;
			default: false;
		});
		var names:Array<String> = [];
		ElixirASTChildren.walk(mapped, child -> collectVarName(child, names));

		assertStrings(["mapped_outside", "inside"], names, "transformNodeUntil lexical boundary");
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
