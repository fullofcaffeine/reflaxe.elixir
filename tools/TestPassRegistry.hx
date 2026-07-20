package tools;

#if macro
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirASTTransformer.PassConfig;
import reflaxe.elixir.ast.transformers.registry.ElixirASTPassRegistry;
import reflaxe.elixir.ast.transformers.registry.PassInventory;
import reflaxe.elixir.ast.transformers.registry.PassPipeline;
import reflaxe.elixir.ast.transformers.registry.RegistryCore;
import reflaxe.elixir.ast.transformers.registry.RegistryCore.RegistryDiagnostics;
import reflaxe.elixir.ast.transformers.registry.RegistryCore.RegistryValidationOptions;

/** Focused executable contract for fail-closed pass registration and scheduling. */
class TestPassRegistry {
	public static function run():Expr {
		testDuplicatePassIdsFail();
		testMissingHardTargetsFailInBothDirections();
		testOptionalTargetsMayBeAbsent();
		testPresentOptionalTargetsStillConstrainOrder();
		testCyclesFail();
		testEffectiveOrderViolationsFail();
		testPhaseRegressionsAndUnknownPhasesFail();
		testRepositoryRegistryIsHealthy();
		testTransparentGroupsPreserveGranularOrder();

		Sys.println("Pass registry contract passed");
		return macro null;
	}

	static function testDuplicatePassIdsFail():Void {
		var passes = [pass("alpha"), pass("alpha")];
		var diagnostics = RegistryCore.analyze(passes);

		assertEquals(1, diagnostics.duplicateNames.length, "one duplicate ID is reported");
		assertEquals("alpha", diagnostics.duplicateNames[0], "the duplicate ID is named");
		expectFailure("duplicate IDs", () -> RegistryCore.validate(passes), "duplicate pass IDs: alpha");
	}

	static function testMissingHardTargetsFailInBothDirections():Void {
		var passes = [
			pass("after_user", ["missing_after"]),
			pass("before_user", null, ["missing_before"])
		];
		var diagnostics = RegistryCore.analyze(passes);

		assertEquals(2, diagnostics.missingDependencies.length, "both hard relationship directions are checked");
		assertMissing(diagnostics, RegistryCore.RUN_AFTER, "missing_after", "after_user");
		assertMissing(diagnostics, RegistryCore.RUN_BEFORE, "missing_before", "before_user");
		expectFailure("missing hard targets", () -> RegistryCore.validate(passes), "missing hard runAfter target missing_after");
	}

	static function testOptionalTargetsMayBeAbsent():Void {
		var passes = [pass("alpha", null, null, ["disabled_before_alpha"], ["disabled_after_alpha"])];
		var diagnostics = RegistryCore.analyze(passes, effectiveOptions());

		assertClean(diagnostics, "absent optional targets");
		RegistryCore.validate(passes, effectiveOptions());
	}

	static function testPresentOptionalTargetsStillConstrainOrder():Void {
		var passes = [
			pass("after_dependent", null, null, ["after_prerequisite"]),
			pass("after_prerequisite"),
			pass("before_target"),
			pass("before_dependent", null, null, null, ["before_target"])
		];
		var diagnostics = RegistryCore.analyze(passes, effectiveOptions());

		assertEquals(2, diagnostics.orderingViolations.length, "present optional targets constrain both relationship directions");
		assertEquals(RegistryCore.RUN_AFTER_IF_PRESENT, diagnostics.orderingViolations[0].relation, "the optional relationship is retained");
		assertEquals(RegistryCore.RUN_BEFORE_IF_PRESENT, diagnostics.orderingViolations[1].relation, "the optional before relationship is retained");
	}

	static function testCyclesFail():Void {
		var passes = [pass("alpha", ["beta"]), pass("beta", ["alpha"])];
		var diagnostics = RegistryCore.analyze(passes);

		assertEquals("alpha,beta", diagnostics.cycleNodes.join(","), "every pass in the cycle is reported");
		expectFailure("ordering cycle", () -> RegistryCore.validate(passes), "ordering cycle contains: alpha, beta");
	}

	static function testEffectiveOrderViolationsFail():Void {
		var afterPasses = [pass("dependent", ["prerequisite"]), pass("prerequisite")];

		// Definition validation happens before the stable sorter and therefore does not
		// mistake source registration order for the established effective order.
		RegistryCore.validate(afterPasses);
		expectFailure("effective runAfter order", () -> RegistryCore.validate(afterPasses, effectiveOptions()),
			"dependent at 1 declares runAfter prerequisite at 2");

		var beforePasses = [pass("target"), pass("dependent", null, ["target"])];
		RegistryCore.validate(beforePasses);
		expectFailure("effective runBefore order", () -> RegistryCore.validate(beforePasses, effectiveOptions()),
			"dependent at 2 declares runBefore target at 1");
	}

	static function testPhaseRegressionsAndUnknownPhasesFail():Void {
		var regressed = [
			pass("late", null, null, null, null, "core"),
			pass("early", null, null, null, null, "bootstrap")
		];
		var regressionOptions = effectiveOptions(["bootstrap", "core"]);
		var diagnostics = RegistryCore.analyze(regressed, regressionOptions);

		assertEquals(1, diagnostics.phaseRegressions.length, "backward phase movement is reported");
		expectFailure("phase regression", () -> RegistryCore.validate(regressed, regressionOptions), "phase regressed from late (core) to early (bootstrap)");

		var unknown = [pass("unknown", null, null, null, null, "mystery")];
		expectFailure("unknown phase", () -> RegistryCore.validate(unknown, regressionOptions), "unknown has missing or unknown phase mystery");
	}

	static function testRepositoryRegistryIsHealthy():Void {
		var passes = ElixirASTPassRegistry.getEnabledPasses();
		var phaseOrder = PassInventory.phaseContracts().map(contract -> contract.id);
		var diagnostics = RegistryCore.analyze(passes, effectiveOptions(phaseOrder));

		assertClean(diagnostics, "the repository registry");
	}

	static function testTransparentGroupsPreserveGranularOrder():Void {
		var contracts = PassPipeline.contracts();
		var groups = ElixirASTPassRegistry.getEnabledPassGroups();
		var flattened = PassPipeline.flatten(groups);
		var granular = ElixirASTPassRegistry.getGranularPasses();

		assertEquals(contracts.length, groups.length, "every declared phase has one contributor-facing group");
		assertEquals(granular.length, flattened.length, "transparent groups contain every enabled granular pass exactly once");

		for (groupIndex in 0...groups.length) {
			var contract = contracts[groupIndex];
			var group = groups[groupIndex];

			assertEquals(contract.name, group.name, "group order is stable");
			assertEquals(contract.phase, group.phase, "group phase is stable");

			for (child in group.children) {
				assertEquals(group.phase, child.phase, 'child ${child.name} remains in its frozen phase');
				assertEquals(group.name, child.group, 'child ${child.name} names its contributor-facing group');
			}
		}

		for (index in 0...granular.length) {
			assertEquals(granular[index].name, flattened[index].name, "flattening preserves granular pass order");
			assertEquals(granular[index].phase, flattened[index].phase, "flattening preserves phase assignment");
			assertEquals(granular[index].scope, flattened[index].scope, "flattening preserves scope assignment");
		}
	}

	static function pass(name:String, ?runAfter:Array<String>, ?runBefore:Array<String>, ?runAfterIfPresent:Array<String>, ?runBeforeIfPresent:Array<String>,
			?phase:String = "bootstrap"):PassConfig {
		return {
			name: name,
			description: name,
			enabled: true,
			pass: ast -> ast,
			phase: phase,
			runAfter: runAfter,
			runBefore: runBefore,
			runAfterIfPresent: runAfterIfPresent,
			runBeforeIfPresent: runBeforeIfPresent
		};
	}

	static function effectiveOptions(?phaseOrder:Array<String>):RegistryValidationOptions {
		return {
			requireEffectiveOrder: true,
			phaseOrder: phaseOrder == null ? ["bootstrap"] : phaseOrder
		};
	}

	static function assertMissing(diagnostics:RegistryDiagnostics, relation:String, dependencyName:String, user:String):Void {
		for (entry in diagnostics.missingDependencies)
			if (entry.relation == relation && entry.name == dependencyName && entry.users.join(",") == user)
				return;
		throw 'Expected missing $relation target $dependencyName referenced by $user';
	}

	static function assertClean(diagnostics:RegistryDiagnostics, label:String):Void {
		assertEquals(0, diagnostics.duplicateNames.length, label + " has no duplicate IDs");
		assertEquals(0, diagnostics.missingDependencies.length, label + " has no missing hard targets");
		assertEquals(0, diagnostics.cycleNodes.length, label + " has no cycles");
		assertEquals(0, diagnostics.orderingViolations.length, label + " satisfies declared order");
		assertEquals(0, diagnostics.phaseRegressions.length, label + " has monotonic phases");
		assertEquals(0, diagnostics.invalidPhases.length, label + " has known phases");
	}

	static function expectFailure(label:String, operation:Void->Void, expectedMessage:String):Void {
		try {
			operation();
		} catch (error:Dynamic) {
			var message = Std.string(error);
			if (message.indexOf(expectedMessage) < 0)
				throw '$label produced the wrong diagnostic: $message';
			return;
		}
		throw '$label did not fail closed';
	}

	static function assertEquals<T>(expected:T, actual:T, label:String):Void {
		if (expected != actual)
			throw '$label: expected $expected, got $actual';
	}
}
#end
