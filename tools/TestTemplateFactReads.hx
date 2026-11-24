package tools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.TemplateFactReads;
import reflaxe.elixir.TemplateFactSources.TemplateFact;

/**
 * Focused executable contract for `TemplateFactReads`: which types a warm
 * request builds again after a template fact changes.
 *
 * The server-cache test (`npm run test:reflaxe-server-cache`) proves the rule
 * end to end with a real compilation server. This test covers the fallbacks
 * that the end-to-end test cannot reach: a type without a record, a read of
 * the whole component index, a removed fact, and a read outside any build.
 *
 * Each request below is simulated: `beginRequest` with the facts, builds that
 * note their reads, and `commit` for a published request. Outside a
 * compilation server every type counts as typed again, so each fingerprint is
 * computed from the type.
 */
class TestTemplateFactReads {
	static inline final PAGE = "page";
	static inline final QUIET = "quiet";
	static inline final HOOKS_PAGE = "hooks-page";
	static inline final TOOL = "tool";
	static inline final NEW_TYPE = "new-type";
	static inline final PROPS = "props";
	static inline final REGISTRY = "registry";

	public static function run():Expr {
		var badge = TemplateFactReads.componentRead("badge");
		var propsBefore = typedefFact("haxe.PosInfos", [badge]);
		var propsAfter = typedefFact("haxe.macro.Expr.Function", [badge]);
		var registry = typedefFact("haxe.macro.Expr.MetadataEntry", [TemplateFactReads.HOOK_NAMES]);
		var live = [PAGE, QUIET, HOOKS_PAGE, TOOL, NEW_TYPE];

		// 1. The first published request: the page reads `badge`, another page
		// reads the hook registry, a tool reads the whole component index, and
		// a quiet template reads nothing.
		TemplateFactReads.beginRequest([PROPS => propsBefore, REGISTRY => registry]);
		build(PAGE, [badge]);
		build(HOOKS_PAGE, [TemplateFactReads.HOOK_NAMES]);
		build(TOOL, [TemplateFactReads.ALL_COMPONENTS]);
		build(QUIET, []);
		TemplateFactReads.commit();

		// 2. The same facts again: only the type without a record is built.
		TemplateFactReads.beginRequest([PROPS => propsBefore, REGISTRY => registry]);
		expectBuilds(live, [NEW_TYPE], 0, "unchanged facts");
		TemplateFactReads.commit();

		// 3. The props change: the page that looks up `badge` and the tool that
		// read the whole index; the hook page and the quiet page are not built.
		TemplateFactReads.beginRequest([PROPS => propsAfter, REGISTRY => registry]);
		expectBuilds(live, [PAGE, TOOL, NEW_TYPE], 2, "changed props");
		build(PAGE, [badge]);
		build(TOOL, [TemplateFactReads.ALL_COMPONENTS]);
		TemplateFactReads.commit();

		// 4. The registry is removed: its published read counts as changed.
		TemplateFactReads.beginRequest([PROPS => propsAfter]);
		expectBuilds(live, [HOOKS_PAGE, NEW_TYPE], 1, "removed registry");
		build(HOOKS_PAGE, [TemplateFactReads.HOOK_NAMES]);
		TemplateFactReads.commit();

		// 5. A failed request does not publish: the next one compares with the
		// published props, so the same change is found again.
		TemplateFactReads.beginRequest([PROPS => propsBefore]);
		build(PAGE, []);
		TemplateFactReads.beginRequest([PROPS => propsBefore]);
		expectBuilds(live, [PAGE, TOOL, NEW_TYPE], 2, "after a failed request");
		TemplateFactReads.commit();

		// 6. A read outside any build drops every record: every type is built.
		TemplateFactReads.beginRequest([PROPS => propsBefore]);
		TemplateFactReads.note(badge);
		TemplateFactReads.commit();
		TemplateFactReads.beginRequest([PROPS => propsAfter]);
		expectBuilds(live, live, 0, "after a read outside a build");

		// The fingerprint ignores Reflaxe's request token and source positions,
		// and changes with a field.
		var posInfos = Context.getType("haxe.PosInfos");
		var first = TemplateFactReads.fingerprint(moduleTypeOf(posInfos));
		switch (posInfos) {
			case TType(defRef, _):
				defRef.get().meta.add(":reflaxe.typedIn", [macro "token", macro "owner"], Context.currentPos());
			case _:
		}
		assertEquals(first, TemplateFactReads.fingerprint(moduleTypeOf(posInfos)), "the request token is not part of a fingerprint");
		if (first.indexOf("lineNumber") < 0)
			throw "a typedef fingerprint must hold its fields";

		Sys.println("Template fact reads contract passed");
		return macro null;
	}

	static function build(key:String, reads:Array<String>):Void {
		TemplateFactReads.beginBuild(key);
		for (read in reads)
			TemplateFactReads.note(read);
		TemplateFactReads.endBuild();
	}

	static function expectBuilds(live:Array<String>, expected:Array<String>, expectedReaders:Int, label:String):Void {
		var readers = -1;
		var builds = TemplateFactReads.buildsForChangedFacts(live, count -> readers = count);
		var actual = [for (key in live) if (builds.exists(key)) key];
		assertEquals(expected.join(","), actual.join(","), label + ": built types");
		assertEquals(Std.string(expectedReaders), Std.string(readers), label + ": readers with a record");
	}

	static function typedefFact(path:String, reads:Array<String>):TemplateFact {
		return {moduleType: moduleTypeOf(Context.getType(path)), reads: reads};
	}

	static function moduleTypeOf(type:Type):ModuleType {
		return switch (type) {
			case TType(defRef, _): TTypeDecl(defRef);
			case _: throw "expected a typedef";
		}
	}

	static function assertEquals(expected:String, actual:String, label:String):Void {
		if (expected != actual)
			throw '$label: expected `$expected`, got `$actual`';
	}
}
#end
