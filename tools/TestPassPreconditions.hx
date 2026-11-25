package tools;

#if macro
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTStructuralDigest;
import reflaxe.elixir.ast.PassFeatureScan;
import reflaxe.elixir.ast.PassPrecondition;
import reflaxe.elixir.ast.transformers.registry.ElixirASTPassRegistry;
import reflaxe.elixir.ast.transformers.registry.PassPreconditionManifest;

/**
 * Executable contract for pass preconditions and the feature scan.
 *
 * It checks that the scan sees every binder position (a missed position could
 * let a pass be skipped while it would rename that binder), that each condition
 * form answers as documented, that bad declarations fail, that the manifest
 * reaches the effective registry, and that the verification equality notices
 * metadata-only changes.
 */
class TestPassPreconditions {
	public static function run():Expr {
		testScanSeesEveryBinderPosition();
		testConditionForms();
		testInvalidDeclarationsFail();
		testManifestReachesRegistry();
		testVerificationEquality();
		Sys.println("Pass precondition contract passed");
		return macro null;
	}

	static function testScanSeesEveryBinderPosition():Void {
		var body = makeAST(EVar("body_ref"));
		var tree = makeAST(EBlock([
			makeAST(EDef("def_fun", [PVar("def_arg")], null, body)),
			makeAST(EDefp("defp_fun", [PTuple([PVar("defp_arg")])], null, body)),
			makeAST(EDefmacro("macro_fun", [PVar("macro_arg")], null, body)),
			makeAST(EDefmacrop("macrop_fun", [PVar("macrop_arg")], null, body)),
			makeAST(EMatch(PAlias("alias_name", PList([PVar("list_item")])), body)),
			makeAST(ECase(body, [
				{
					pattern: PMap([{key: makeAST(EAtom("k")), value: PVar("case_map_value")}]),
					body: body
				}
			])),
			makeAST(EReceive([{pattern: PCons(PVar("receive_head"), PVar("receive_tail")), body: body}], null)),
			makeAST(EWith([
				{pattern: PStruct("User", [{key: "id", value: PVar("with_struct_field")}]), expr: body}
			],
				body, null)),
			makeAST(ETry(body, [{pattern: PVar("rescue_pattern"), varName: "rescue_var", body: body}],
				[{kind: Throw, pattern: PPin(PVar("catch_pin")), body: body}], null, null)),
			makeAST(EFor([{pattern: PVar("for_item"), expr: body}], [], body, null, false)),
			makeAST(EFn([{args: [PVar("fn_arg")], body: body}]))
		]));
		var scan = PassFeatureScan.scan(tree);
		for (name in [
			"body_ref",
			"def_arg",
			"defp_arg",
			"macro_arg",
			"macrop_arg",
			"alias_name",
			"list_item",
			"case_map_value",
			"receive_head",
			"receive_tail",
			"with_struct_field",
			"rescue_pattern",
			"rescue_var",
			"catch_pin",
			"for_item",
			"fn_arg"
		])
			assertTrue(scan.satisfies(HasName(Exactly(name))), 'scan records binder or variable name $name');
		assertFalse(scan.satisfies(HasName(Exactly("User"))), "struct module names are not binder names");
		assertFalse(scan.satisfies(HasName(Exactly("id"))), "struct field keys are not binder names");
	}

	static function testConditionForms():Void {
		var tree = makeAST(EDef("show", [PVar("conn"), PVar("_params")], null, makeAST(EBlock([
			makeAST(EMatch(PVar("value2"), makeAST(ERemoteCall(makeAST(EVar("Phoenix.Controller")), "json", [makeAST(EVar("conn")), makeAST(EVar("data"))])))),
			makeAST(ECall(makeAST(EVar("Map")), "get", [makeAST(EVar("userId")), makeAST(EString("k"))])),
			makeAST(ECall(null, "local_helper", []))
		]))));
		var scan = PassFeatureScan.scan(tree);
		assertTrue(scan.satisfies(HasNode("EDef")), "constructor present");
		assertFalse(scan.satisfies(HasNode("EStructUpdate")), "constructor absent");
		assertTrue(scan.satisfies(CallTo("Phoenix.Controller", "json")), "remote call");
		assertTrue(scan.satisfies(CallTo("Map", "get")), "ECall with a module target counts as a module call");
		assertFalse(scan.satisfies(CallTo("Phoenix.Controller", "render")), "other function of the same module");
		assertFalse(scan.satisfies(CallTo("Map", "json")), "same function on another module");
		assertTrue(scan.satisfies(CallNamed("local_helper")), "local call name");
		assertTrue(scan.satisfies(CallNamed("json")), "remote call name");
		assertFalse(scan.satisfies(CallNamed("conn")), "a variable is not a call");
		assertTrue(scan.satisfies(HasName(UnderscoredBinder)), "_params is an underscored binder");
		assertTrue(scan.satisfies(HasName(StartsWith("_p"))), "prefix");
		assertTrue(scan.satisfies(HasName(EndsWithDigit)), "value2 ends with a digit");
		assertTrue(scan.satisfies(HasName(HasUppercase)), "userId has an upper-case letter");
		assertTrue(scan.satisfies(AnyOf([HasNode("EStructUpdate"), CallNamed("json")])), "AnyOf needs one");
		assertFalse(scan.satisfies(AllOf([HasNode("EStructUpdate"), CallNamed("json")])), "AllOf needs all");

		var plain = PassFeatureScan.scan(makeAST(EDef("run", [PVar("_")], null, makeAST(EVar("value")))));
		assertFalse(plain.satisfies(HasName(UnderscoredBinder)), "a lone _ is not an underscored binder");
		assertTrue(plain.satisfies(HasName(StartsWith("_"))), "a lone _ starts with _");
		assertFalse(plain.satisfies(HasName(EndsWithDigit)), "no digit suffix");
		assertFalse(plain.satisfies(HasName(HasUppercase)), "no upper-case letter");
	}

	static function testInvalidDeclarationsFail():Void {
		assertThrows(() -> PassFeatureScan.validate("Sample", HasNode("ENotAConstructor")), "unknown constructor");
		assertThrows(() -> PassFeatureScan.validate("Sample", AnyOf([])), "empty AnyOf");
		assertThrows(() -> PassFeatureScan.validate("Sample", CallTo("", "json")), "empty module");
		assertThrows(() -> PassFeatureScan.validate("Sample", HasName(StartsWith(""))), "empty prefix");
		PassFeatureScan.validate("Sample", AllOf([HasNode("ECase"), CallTo("Map", "get")]));
	}

	static function testManifestReachesRegistry():Void {
		var declarations = PassPreconditionManifest.declarations();
		var passes = ElixirASTPassRegistry.getEnabledPasses();
		var applied = 0;
		for (pass in passes)
			if (pass.precondition != null) {
				applied++;
				assertTrue(declarations.exists(pass.name), 'precondition on ${pass.name} comes from the manifest');
			}
		var declared = 0;
		for (_ in declarations.keys())
			declared++;
		assertTrue(declared > 0, "the manifest declares preconditions");
		assertEquals(declared, applied, "every declaration reaches exactly one effective pass");
	}

	static function testVerificationEquality():Void {
		var leaf = makeAST(EVar("value"));
		var tree = makeAST(EBlock([leaf, makeAST(ECase(leaf, [{pattern: PVar("x"), body: leaf}]))]));
		assertTrue(ElixirASTStructuralDigest.equivalent(tree, tree), "same object");

		var rebuilt = makeASTWithMeta(EBlock([
			leaf,
			makeASTWithMeta(ECase(leaf, [{pattern: PVar("x"), body: leaf}]), tree.metadata, tree.pos)
		]), tree.metadata, tree.pos);
		var original = makeASTWithMeta(EBlock([
			leaf,
			makeASTWithMeta(ECase(leaf, [{pattern: PVar("x"), body: leaf}]), tree.metadata, tree.pos)
		]), tree.metadata, tree.pos);
		assertTrue(ElixirASTStructuralDigest.equivalent(original, rebuilt), "a rebuilt tree with the same values is equivalent");

		var renamed = makeASTWithMeta(EBlock([
			leaf,
			makeASTWithMeta(ECase(leaf, [{pattern: PVar("y"), body: leaf}]), tree.metadata, tree.pos)
		]), tree.metadata, tree.pos);
		assertFalse(ElixirASTStructuralDigest.equivalent(original, renamed), "a renamed binder is a change");

		var flagged = makeASTWithMeta(EVar("value"), {isLiveView: true}, leaf.pos);
		var plain = makeASTWithMeta(EVar("value"), {}, leaf.pos);
		assertEquals(ElixirASTStructuralDigest.digest(plain), ElixirASTStructuralDigest.digest(flagged), "the digest ignores metadata");
		assertFalse(ElixirASTStructuralDigest.equivalent(plain, flagged), "equivalence sees a metadata-only change");
		assertTrue(ElixirASTStructuralDigest.equivalent(plain, makeASTWithMeta(EVar("value"), {}, leaf.pos)), "equal empty metadata records match");
	}

	static function assertThrows(action:() -> Void, label:String):Void {
		var threw = false;
		try
			action()
		catch (_:Dynamic)
			threw = true;
		assertTrue(threw, 'expected a failure: $label');
	}

	static function assertTrue(condition:Bool, label:String):Void {
		if (!condition)
			throw label;
	}

	static function assertFalse(condition:Bool, label:String):Void {
		assertTrue(!condition, label);
	}

	static function assertEquals<T>(expected:T, actual:T, label:String):Void {
		if (expected != actual)
			throw '$label: expected $expected, got $actual';
	}
}
#end
