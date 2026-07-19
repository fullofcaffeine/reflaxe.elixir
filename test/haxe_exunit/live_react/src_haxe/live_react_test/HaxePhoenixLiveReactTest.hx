package live_react_test;

import elixir.ElixirMap;
import elixir.ElixirString;
import elixir.ErlangBinary;
import elixir.File;
import elixir.Path;
import elixir.System;
import elixir.mix.DependencyLock;
import elixir.types.Atom;
import elixir.types.Term;
import haxe.test.Assert;
import haxe.test.ExUnit.TestCase;
import live_react_test.LiveReactFixture as Fixture;
import live_react_test.LiveReactFixture.MixDependencyName;

/**
 * Full behavioral contract for the public PhoenixHx LiveReact lifecycle.
 *
 * The suite is authored in Haxe and compiled to ExUnit so the repository
 * dogfoods the same Haxe→Elixir path that application tests use. Native maps,
 * keyword lists, filesystem calls, and Mix modules remain explicit typed
 * BEAM boundaries; no target-code injection is used.
 */
@:exunit
@:async
@:native("HaxePhoenixLiveReactTest")
class HaxePhoenixLiveReactTest extends TestCase {
	static inline final CHECK:Atom = "check";
	static inline final LIVE_REACT:Atom = "live_react";
	static inline final PHOENIX:Atom = "phoenix";
	static inline final DOLLAR_SIGN = "$";

	@:test("Genes project at the root applies, checks, recovers generated files, and removes")
	function testGenesProjectAtRootAppliesChecksRecoversAndRemoves():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		var originals = Fixture.originalSources(root);
		var result = LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		Assert.equals(".", result.packageRoot);
		Assert.equals(Fixture.GENES, result.clientMode);
		Assert.equals("file:deps/live_react", result.npmReference);
		Assert.equals(Fixture.REVISION, Fixture.jsonPath(result.dependency, ["resolvedRevision"]));
		Assert.containsString(File.readBang(Path.joinTwo(root, "mix.exs")), "BEGIN reflaxe_elixir live_react_dependency");
		Assert.containsString(File.readBang(Path.join([root, "config", "dev.exs"])), 'vite: ["npm", "run", "assets:dev", cd: Path.expand("../", __DIR__)]');
		Assert.containsString(File.readBang(Path.join([root, "assets", "js", "app.js"])), "Object.assign(Hooks, reactHooks);");
		Assert.containsString(File.readBang(Fixture.rootLayout(root)),
			"<%!-- BEGIN reflaxe_elixir live_react_vite_assets --%>\n"
			+ "    <LiveReact.Reload.vite_assets assets={[\"/js/app.js\"]}>\n"
			+ "      <script defer phx-track-static type=\"text/javascript\" src={~p\"/assets/app.js\"}></script>\n"
			+ "    </LiveReact.Reload.vite_assets>\n"
			+ "    <%!-- END reflaxe_elixir live_react_vite_assets --%>");

		Assert.isTrue(ElixirMap.hasKeyTerm(DependencyLock.read(Path.joinTwo(root, "mix.lock")), LIVE_REACT));
		Assert.containsString(File.readBang(Path.joinTwo(root, "vite.config.mjs")), Fixture.GENERATED_SIGNATURE);
		var manifest = Fixture.readJson(Path.joinTwo(root, Fixture.MANIFEST));
		Assert.isEmpty(Fixture.jsonPath(manifest, ["components"]));
		var originalLockState:Term = Fixture.jsonPath(manifest, ["managed", "restores", "mix.lockOriginalState"]);
		Assert.equals("empty", Fixture.jsonPath(originalLockState, ["kind"]));
		Assert.equals("%{}\n", Fixture.jsonPath(originalLockState, ["content"]));

		Assert.equals(CHECK, LifecycleApi.checkBang(root, Fixture.rerunOptions()).mode);

		var registryPath = Path.join([root, "assets", "react-components", "registry.generated.ts"]);
		File.rmBang(registryPath);
		LifecycleApi.applyBang(root, Fixture.rerunOptions());

		Assert.isTrue(File.regular(registryPath));

		var afterRecovery = Fixture.treeSnapshot(root);
		LifecycleApi.applyBang(root, Fixture.rerunOptions());
		Assert.equals(afterRecovery, Fixture.treeSnapshot(root));

		var removed = LifecycleApi.removeBang(root, [{_0: "yes", _1: true}]);

		Assert.isEmpty(removed.retainedPackageKeys);
		Assert.isFalse(File.exists(Path.joinTwo(root, Fixture.MANIFEST)));
		Assert.isFalse(File.exists(Path.joinTwo(root, "vite.config.mjs")));
		Assert.isFalse(File.exists(Path.join([root, "assets", "js", "live-react-hooks.js"])));
		Assert.isFalse(File.exists(registryPath));
		Assert.isFalse(ElixirMap.hasKeyTerm(DependencyLock.read(Path.joinTwo(root, "mix.lock")), LIVE_REACT));
		Assert.equals(originals.appJs, File.readBang(Path.join([root, "assets", "js", "app.js"])));
		Assert.equals(originals.rootLayout, File.readBang(Fixture.rootLayout(root)));
		Assert.equals(originals.devExs, File.readBang(Path.join([root, "config", "dev.exs"])));
		Assert.equals(originals.configExs, File.readBang(Path.join([root, "config", "config.exs"])));
		Assert.equals(originals.mixExs, File.readBang(Path.joinTwo(root, "mix.exs")));
		Assert.equals(originals.mixLock, File.readBang(Path.joinTwo(root, "mix.lock")));

		var packageJson = Fixture.readJson(Path.joinTwo(root, "package.json"));

		Assert.equals(1, ElixirMap.sizeTerm(packageJson));
		Assert.equals("demo-assets", Fixture.jsonPath(packageJson, ["name"]));
	}

	@:test("plain-JS project with an assets package root preserves its existing hook expression")
	function testPlainJsAssetsPackagePreservesHookExpression():Void {
		var root = Fixture.fixtureRoot(Fixture.PLAIN_JS, "assets");
		var originalAppJs = File.readBang(Path.join([root, "assets", "js", "app.js"]));

		var result = LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		Assert.equals("assets", result.packageRoot);
		Assert.equals(Fixture.PLAIN_JS, result.clientMode);
		Assert.equals("file:../deps/live_react", result.npmReference);

		var appJs = File.readBang(Path.join([root, "assets", "js", "app.js"]));

		Assert.containsString(appJs, "window.Hooks = {...(window.Hooks || {}), ...reactHooks}");
		Assert.containsString(appJs, "hooks: {...colocatedHooks, ...(window.Hooks || {})},");
		Assert.containsString(File.readBang(Path.join([root, "config", "dev.exs"])),
			'vite: ["npm", "run", "assets:dev", cd: Path.expand("../assets", __DIR__)]');

		var packageJson = Fixture.readJson(Path.join([root, "assets", "package.json"]));

		Assert.equals("file:../deps/live_react", Fixture.jsonPath(packageJson, ["dependencies", "live_react"]));
		Assert.equals("assets", LifecycleApi.checkBang(root, Fixture.rerunOptions()).packageRoot);

		LifecycleApi.removeBang(root, [{_0: "yes", _1: true}]);

		Assert.equals(originalAppJs, File.readBang(Path.join([root, "assets", "js", "app.js"])));
		Assert.isFalse(File.exists(Path.joinTwo(root, Fixture.MANIFEST)));
	}

	@:test("the owned JavaScript registry migrates explicitly to the typed registry")
	function testOwnedJavascriptRegistryMigratesToTypedRegistry():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		var typed = Path.join([root, "assets", "react-components", "registry.generated.ts"]);
		var legacy = Path.join([root, "assets", "react-components", "registry.generated.js"]);
		File.renameBang(typed, legacy);

		var manifestPath = Path.joinTwo(root, Fixture.MANIFEST);
		var manifest = Fixture.readJson(manifestPath);
		var managed:Term = Fixture.jsonPath(manifest, ["managed"]);
		var files:Array<String> = Fixture.jsonPath(manifest, ["managed", "files"]);
		var legacyFiles = elixir.Enum.map(files, function(relative:String):String {
			return relative == "assets/react-components/registry.generated.ts" ? "assets/react-components/registry.generated.js" : relative;
		});
		managed = ElixirMap.putTerm(managed, "files", elixir.Enum.sort(legacyFiles));
		manifest = ElixirMap.putTerm(manifest, "managed", managed);
		File.writeBang(manifestPath, Fixture.encodePretty(manifest));

		var beforeCheck = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.checkBang(root, Fixture.rerunOptions());
		}, "integration drift detected");
		Assert.equals(beforeCheck, Fixture.treeSnapshot(root));

		LifecycleApi.applyBang(root, Fixture.rerunOptions());

		Assert.isFalse(File.exists(legacy));
		Assert.isTrue(File.regular(typed));

		var migrated = Fixture.readJson(manifestPath);
		var migratedFiles:Array<String> = Fixture.jsonPath(migrated, ["managed", "files"]);

		Assert.contains(migratedFiles, "assets/react-components/registry.generated.ts");
		Assert.isFalse(elixir.Enum.any(migratedFiles, function(relative:String):Bool return relative == "assets/react-components/registry.generated.js"));
	}

	@:test("component registration creates a sorted static registry and hand-owned typed boundaries")
	function testComponentRegistrationCreatesSortedRegistryAndTypedBoundaries():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		var zeta = LifecycleApi.addComponentBang(root, "ZetaPanel", Fixture.componentOptions());
		var alpha = LifecycleApi.addComponentBang(root, "AlphaPanel", Fixture.componentOptions());

		Assert.equals([
			"src_haxe/demo_hx/components/live_react/ZetaPanelIsland.hx",
			"assets/react-components/zeta-panel-boundary.tsx",
			"assets/react-components/zeta-panel.tsx"
		], zeta.createdFiles);
		Assert.equals([
			"src_haxe/demo_hx/components/live_react/AlphaPanelIsland.hx",
			"assets/react-components/alpha-panel-boundary.tsx",
			"assets/react-components/alpha-panel.tsx"
		], alpha.createdFiles);

		var manifest = Fixture.readJson(Path.joinTwo(root, Fixture.MANIFEST));
		var components:Array<Term> = Fixture.jsonPath(manifest, ["components"]);
		var names = elixir.Enum.map(components, function(component:Term):String return ElixirMap.fetchBangTerm(component, "name"));

		Assert.equals(["AlphaPanel", "ZetaPanel"], names);

		var registryPath = Path.join([root, "assets", "react-components", "registry.generated.ts"]);
		var registry = File.readBang(registryPath);

		Assert.containsString(registry, 'import {AlphaPanelBoundary as AlphaPanelComponent} from "./alpha-panel-boundary"');
		Assert.containsString(registry, 'import {ZetaPanelBoundary as ZetaPanelComponent} from "./zeta-panel-boundary"');
		Assert.containsString(registry, "export type ComponentName = keyof typeof componentRegistry");
		Assert.isTrue(ErlangBinary.matchFound(registry, "AlphaPanel:")._0 < ErlangBinary.matchFound(registry, "ZetaPanel:")._0);
		Assert.doesNotContainString(registry, "import(");
		Assert.doesNotContainString(registry, "glob");

		var wrapper = File.readBang(Path.join([root, "src_haxe", "demo_hx", "components", "live_react", "AlphaPanelIsland.hx"]));
		Assert.containsString(wrapper, "private typedef AlphaPanelAssigns");
		Assert.containsString(wrapper, "return <div");
		Assert.containsString(wrapper, "<LiveReact.react");
		Assert.containsString(wrapper, 'name="AlphaPanel"');
		Assert.containsString(wrapper, "id=" + DOLLAR_SIGN + "{assigns.id}");
		Assert.containsString(wrapper, "ssr=" + DOLLAR_SIGN + "{false}");
		Assert.doesNotContainString(wrapper, "HXX.hxx");
		Assert.doesNotContainString(wrapper, "hxx(");
		Assert.doesNotContainString(wrapper, "<%");

		var boundary = File.readBang(Path.join([root, "assets", "react-components", "alpha-panel-boundary.tsx"]));
		var innerPath = Path.join([root, "assets", "react-components", "alpha-panel.tsx"]);
		var inner = File.readBang(innerPath);

		Assert.containsString(boundary, "export type AlphaPanelRawProps = Record<string, unknown>");
		Assert.containsString(boundary, "const nativeBridgeKeys");
		Assert.containsString(boundary, "Unexpected AlphaPanel input");
		Assert.doesNotContainString(boundary, "raw.pushEvent");
		Assert.doesNotContainString(boundary, "alpha_panel_action");
		Assert.containsString(boundary, '<section role="alert"');
		Assert.containsString(inner, "readonly title: string");
		Assert.doesNotContainString(inner, "onAction");
		Assert.doesNotContainString(inner, "pushEvent");
		Assert.doesNotContainString(inner, "uploadTo");

		File.writeBang(innerPath, inner + "\n// application-owned edit\n");
		var beforeRerun = Fixture.treeSnapshot(root);

		var rerun = LifecycleApi.addComponentBang(root, "AlphaPanel", Fixture.componentOptions());

		Assert.isEmpty(rerun.changes);
		Assert.equals(beforeRerun, Fixture.treeSnapshot(root));

		var removed = LifecycleApi.removeComponentBang(root, "AlphaPanel", Fixture.componentOptions());

		Assert.contains(removed.retainedFiles, "assets/react-components/alpha-panel.tsx");
		Assert.containsString(File.readBang(innerPath), "application-owned edit");
		Assert.doesNotContainString(File.readBang(registryPath), "AlphaPanel");
	}

	@:test("an existing reviewed boundary can be adopted without scaffolding or source ownership")
	function testExistingReviewedBoundaryCanBeAdopted():Void {
		var root = Fixture.fixtureRoot(Fixture.PLAIN_JS, "assets");
		LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		var custom = "assets/react-components/custom-boundary.tsx";
		Fixture.write(root, custom, "export function CustomBoundary() { return null }\n");

		var result = LifecycleApi.addComponentBang(root, "CustomPanel", Fixture.componentOptions(true, "./custom-boundary", "CustomBoundary"));

		Assert.isEmpty(result.createdFiles);
		Assert.containsString(File.readBang(Path.join([root, "assets", "react-components", "registry.generated.ts"])),
			'import {CustomBoundary as CustomPanelComponent} from "./custom-boundary"');
		Assert.isFalse(File.exists(Path.join([root, "src_haxe", "demo_hx", "components", "live_react", "CustomPanelIsland.hx"])));

		var removed = LifecycleApi.removeComponentBang(root, "CustomPanel", Fixture.componentOptions());

		Assert.contains(removed.retainedFiles, custom);
		Assert.equals("export function CustomBoundary() { return null }\n", File.readBang(Path.joinTwo(root, custom)));
	}

	@:test("full removal retains scaffolded source without retaining now-unused browser dependencies")
	function testFullRemovalRetainsScaffoldedSourceWithoutUnusedDependencies():Void {
		var root = Fixture.fixtureRoot(Fixture.PLAIN_JS, "assets");
		LifecycleApi.applyBang(root, Fixture.applyOptions(root));
		LifecycleApi.addComponentBang(root, "StatusPanel", Fixture.componentOptions());

		var result = LifecycleApi.removeBang(root, [{_0: "yes", _1: true}]);
		var packageJson = Fixture.readJson(Path.join([root, "assets", "package.json"]));

		Assert.isEmpty(result.retainedPackageKeys);
		Assert.isFalse(result.retainedLiveReactDependency);
		Assert.isTrue(File.regular(Path.join([root, "src_haxe", "demo_hx", "components", "live_react", "StatusPanelIsland.hx"])));
		Assert.isTrue(File.regular(Path.join([root, "assets", "react-components", "status-panel-boundary.tsx"])));
		Assert.isTrue(File.regular(Path.join([root, "assets", "react-components", "status-panel.tsx"])));
		Assert.equals(1, ElixirMap.sizeTerm(packageJson));
		Assert.equals("demo-assets", Fixture.jsonPath(packageJson, ["name"]));
		Assert.isFalse(File.exists(Path.join([root, "assets", "react-components", "registry.generated.ts"])));
		Assert.isFalse(File.exists(Path.joinTwo(root, Fixture.MANIFEST)));
	}

	@:test("component conflicts and missing boundaries fail before any write")
	function testComponentConflictsAndMissingBoundariesAreAtomic():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		var beforeInvalid = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.addComponentBang(root, "request-selected", Fixture.componentOptions());
		}, "static PascalCase");
		Assert.equals(beforeInvalid, Fixture.treeSnapshot(root));

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.addComponentBang(root, "EscapingPanel", Fixture.componentOptions(true, "../outside"));
		}, "closed project-relative import");
		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.addComponentBang(root, "InvalidExportPanel", Fixture.componentOptions(true, "./reviewed-boundary", "not-valid!"));
		}, "JavaScript identifier");
		Assert.equals(beforeInvalid, Fixture.treeSnapshot(root));

		var collision = "src_haxe/demo_hx/components/live_react/CollisionPanelIsland.hx";
		Fixture.write(root, collision, "package demo_hx.components.live_react;\n");
		var beforeCollision = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.addComponentBang(root, "CollisionPanel", Fixture.componentOptions());
		}, "hand-owned source file already exists");
		Assert.equals(beforeCollision, Fixture.treeSnapshot(root));

		LifecycleApi.addComponentBang(root, "MissingPanel", Fixture.componentOptions());
		File.rmBang(Path.join([root, "assets", "react-components", "missing-panel-boundary.tsx"]));
		var beforeCheck = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.checkBang(root, Fixture.rerunOptions());
		}, "cannot resolve .*missing-panel-boundary");
		Assert.equals(beforeCheck, Fixture.treeSnapshot(root));
	}

	@:test("duplicate manifest component identities fail without rewriting owned state")
	function testDuplicateManifestComponentIdentityFailsAtomically():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		var manifestPath = Path.joinTwo(root, Fixture.MANIFEST);
		var manifest = Fixture.readJson(manifestPath);
		var duplicate = ElixirMap.new_();
		duplicate = ElixirMap.putTerm(duplicate, "name", "StatusPanel");
		duplicate = ElixirMap.putTerm(duplicate, "module", "./status-panel-boundary");
		duplicate = ElixirMap.putTerm(duplicate, "export", "StatusPanelBoundary");
		manifest = ElixirMap.putTerm(manifest, "components", [duplicate, duplicate]);
		File.writeBang(manifestPath, Fixture.encodePretty(manifest));

		var before = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.checkBang(root, Fixture.rerunOptions());
		}, "duplicate LiveReact component name StatusPanel");
		Assert.equals(before, Fixture.treeSnapshot(root));
	}

	@:test("check reports drift without changing a byte")
	function testCheckReportsDriftWithoutWrites():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		var hooks = Path.join([root, "assets", "js", "live-react-hooks.js"]);
		File.writeBang(hooks, ElixirString.replace(File.readBang(hooks), "reactHooks", "changedHooks"));
		var before = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.checkBang(root, Fixture.rerunOptions());
		}, "integration drift detected");
		Assert.equals(before, Fixture.treeSnapshot(root));
	}

	@:test("an unowned generated path fails before any tracked write")
	function testUnownedGeneratedPathFailsBeforeWrite():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		File.writeBang(Path.joinTwo(root, "vite.config.mjs"), "export default {}\n");
		var before = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.applyBang(root, Fixture.applyOptions(root));
		}, "exists without the PhoenixHx LiveReact ownership signature");
		Assert.equals(before, Fixture.treeSnapshot(root));
	}

	@:test("a conflicting package key fails before any tracked write")
	function testConflictingPackageKeyFailsBeforeWrite():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		var packagePath = Path.joinTwo(root, "package.json");
		File.writeBang(packagePath, "{\"name\":\"demo-assets\",\"scripts\":{\"assets:build\":\"custom\"}}\n");
		var before = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.applyBang(root, Fixture.applyOptions(root));
		}, "scripts.assets:build conflicts");
		Assert.equals(before, Fixture.treeSnapshot(root));
	}

	@:test("package-root traversal is rejected before any tracked write")
	function testPackageRootTraversalFailsBeforeWrite():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		var before = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.applyBang(root, Fixture.packageRootOptions(root, "../assets"));
		}, "project-relative|parent traversal");
		Assert.equals(before, Fixture.treeSnapshot(root));
	}

	@:test("malformed ownership markers fail before any tracked write")
	function testMalformedOwnershipMarkersFailBeforeWrite():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		var config = Path.join([root, "config", "config.exs"]);
		File.writeBang(config, File.readBang(config) + "# BEGIN reflaxe_elixir live_react_config\n");
		var before = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.applyBang(root, Fixture.applyOptions(root));
		}, "malformed or overlapping ownership markers");
		Assert.equals(before, Fixture.treeSnapshot(root));
	}

	@:test("dependency resolution may only change the LiveReact lock entry")
	function testDependencyResolutionCannotChangeUnrelatedLockEntries():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		var before = Fixture.treeSnapshot(root);
		var options = Fixture.applyOptionsWithLock(root, Fixture.lockContent(true, "99.0.0"));

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.applyBang(root, options);
		}, "changed lock entries unrelated to :live_react");
		Assert.equals(before, Fixture.treeSnapshot(root));
	}

	@:test("removal deletes a task-created lockfile and preserves unrelated later lock entries")
	function testRemovalHandlesTaskCreatedAndLaterPopulatedLockfiles():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		var lockPath = Path.joinTwo(root, "mix.lock");
		File.rmBang(lockPath);

		LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		Assert.isTrue(File.regular(lockPath));

		File.writeBang(lockPath, Fixture.lockContent(true, "1.7.24"));
		LifecycleApi.removeBang(root, [{_0: "yes", _1: true}]);

		var retained = DependencyLock.read(lockPath);

		Assert.isTrue(ElixirMap.hasKeyTerm(retained, PHOENIX));
		Assert.isFalse(ElixirMap.hasKeyTerm(retained, LIVE_REACT));

		var secondRoot = Fixture.fixtureRoot(Fixture.GENES, ".");
		var secondLock = Path.joinTwo(secondRoot, "mix.lock");
		File.rmBang(secondLock);

		LifecycleApi.applyBang(secondRoot, Fixture.applyOptions(secondRoot));
		LifecycleApi.removeBang(secondRoot, [{_0: "yes", _1: true}]);

		Assert.isFalse(File.exists(secondLock));
	}

	@:test("a populated lockfile round-trips byte-for-byte")
	function testPopulatedLockfileRoundTripsByteForByte():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		var lockPath = Path.joinTwo(root, "mix.lock");
		var original = Fixture.lockContent(false, "1.7.24");
		File.writeBang(lockPath, original);

		LifecycleApi.applyBang(root, Fixture.applyOptionsWithLock(root, Fixture.lockContent(true, "1.7.24")));
		LifecycleApi.removeBang(root, [{_0: "yes", _1: true}]);

		Assert.equals(original, File.readBang(lockPath));
	}

	@:test("a checkout revision mismatch is rejected before planning writes")
	function testCheckoutRevisionMismatchFailsBeforePlanning():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		var before = Fixture.treeSnapshot(root);
		var options = Fixture.applyOptionsWithRevision(root, function(_checkout:String):String return ElixirString.duplicate("a", 40));

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.applyBang(root, options);
		}, "checkout HEAD does not match mix.lock");
		Assert.equals(before, Fixture.treeSnapshot(root));
	}

	@:test("removal rejects edits inside an owned marker and leaves the tree unchanged")
	function testRemovalRejectsOwnedMarkerDrift():Void {
		var root = Fixture.fixtureRoot(Fixture.GENES, ".");
		LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		var config = Path.join([root, "config", "config.exs"]);
		File.writeBang(config, Fixture.replaceOnce(File.readBang(config), "ssr: false", "ssr: true"));
		var before = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.removeBang(root, [{_0: "yes", _1: true}]);
		}, "content drifted inside its ownership markers");
		Assert.equals(before, Fixture.treeSnapshot(root));
	}

	@:test("removal retains package keys imported by hand-owned browser source")
	function testRemovalRetainsPackageKeysImportedByHandOwnedSource():Void {
		var root = Fixture.fixtureRoot(Fixture.PLAIN_JS, "assets");
		LifecycleApi.applyBang(root, Fixture.applyOptions(root));

		var custom = Path.join([root, "assets", "react-components", "custom.tsx"]);
		File.writeBang(custom,
			"import React from \"react\"\n"
			+ "import {createRoot} from \"react-dom/client\"\n"
			+ "import {getHooks} from \"live_react\"\n\n"
			+ "export const retained = [React, createRoot, getHooks]\n");

		var result = LifecycleApi.removeBang(root, [{_0: "yes", _1: true}]);
		var packageJson = Fixture.readJson(Path.join([root, "assets", "package.json"]));

		Assert.equals(["dependencies.live_react", "dependencies.react", "dependencies.react-dom"], result.retainedPackageKeys);
		Assert.isTrue(result.retainedLiveReactDependency);
		Assert.equals("file:../deps/live_react", Fixture.jsonPath(packageJson, ["dependencies", "live_react"]));
		Assert.equals("19.1.0", Fixture.jsonPath(packageJson, ["dependencies", "react"]));
		Assert.equals("19.1.0", Fixture.jsonPath(packageJson, ["dependencies", "react-dom"]));
		Assert.isTrue(File.regular(custom));

		var mixExs = File.readBang(Path.joinTwo(root, "mix.exs"));

		Assert.containsString(mixExs, "{:live_react,");
		Assert.doesNotContainString(mixExs, "live_react_dependency");
		Assert.isTrue(ElixirMap.hasKeyTerm(DependencyLock.read(Path.joinTwo(root, "mix.lock")), LIVE_REACT));
	}

	@:test("a hand-owned project-relative LiveReact path remains the runtime owner")
	function testHandOwnedProjectRelativeDependencyRemainsRuntimeOwner():Void {
		var root = Fixture.fixtureRoot(Fixture.PLAIN_JS, "assets");
		Fixture.copyLiveReactToVendor(root);
		Fixture.writeMixProject(root, [Fixture.pathDependency(MixDependencyName.LiveReact, "vendor/live_react")]);

		var result = LifecycleApi.applyBang(root, Fixture.pathDependencyOptions("vendor/live_react"));

		Assert.equals("path", Fixture.jsonPath(result.dependency, ["sourceKind"]));
		Assert.equals("file:../vendor/live_react", result.npmReference);
		Assert.doesNotContainString(File.readBang(Path.joinTwo(root, "mix.exs")), "live_react_dependency");

		LifecycleApi.removeBang(root, [{_0: "yes", _1: true}]);

		Assert.containsString(File.readBang(Path.joinTwo(root, "mix.exs")), '{:live_react, path: "vendor/live_react"}');
		Assert.isFalse(File.exists(Path.joinTwo(root, Fixture.MANIFEST)));
	}

	@:test("inline plain-JS hooks fail closed instead of producing invalid JavaScript")
	function testInlinePlainJsHooksFailClosed():Void {
		var root = Fixture.fixtureRoot(Fixture.PLAIN_JS, ".");
		var appJs = Path.join([root, "assets", "js", "app.js"]);
		File.writeBang(appJs,
			"import \"phoenix_html\"\n"
			+ "import {Socket} from \"phoenix\"\n"
			+ "import {LiveSocket} from \"phoenix_live_view\"\n\n"
			+ "const liveSocket = new LiveSocket(\"/live\", Socket, {hooks: {}})\n"
			+ "liveSocket.connect()\n");

		var before = Fixture.treeSnapshot(root);

		Assert.raisesRuntimeErrorMatching(function():Void {
			LifecycleApi.applyBang(root, Fixture.applyOptions(root));
		}, "inline LiveSocket hooks property");
		Assert.equals(before, Fixture.treeSnapshot(root));
	}

	@:test("the public Mix task applies, checks, and removes in an external project")
	function testPublicMixTaskLifecycleInExternalProject():Void {
		var root = Fixture.fixtureRoot(Fixture.PLAIN_JS, "assets");
		var repositoryRoot = File.cwdBang();
		Fixture.copyLiveReactToVendor(root);
		Fixture.writeMixProject(root, [
			Fixture.pathDependency(MixDependencyName.JasonLibrary, Path.join([repositoryRoot, "deps", "jason"]), true),
			Fixture.pathDependency(MixDependencyName.ReflaxeElixir, repositoryRoot),
			Fixture.pathDependency(MixDependencyName.LiveReact, "vendor/live_react")
		]);

		Fixture.formatElixirFile(root, "mix.exs");
		Fixture.formatElixirFile(root, "config/config.exs");
		Fixture.formatElixirFile(root, "config/dev.exs");

		Fixture.runExternalMix(root, ["deps.get"]);
		Fixture.runExternalMix(root, ["deps.compile", "reflaxe_elixir"]);

		var applyOutput = Fixture.runLiveReactTask(root, ["--yes"]);

		Assert.containsString(applyOutput, "PhoenixHx LiveReact integration is current");
		Assert.containsString(applyOutput, "path:vendor/live_react@0.1.0");

		var componentOutput = Fixture.runExternalMix(root, ["haxe.gen.live_react", "StatusPanel", "--yes"]);

		Assert.containsString(componentOutput, "StatusPanel is registered in the static registry");
		Assert.isTrue(File.regular(Path.join([root, "assets", "react-components", "status-panel-boundary.tsx"])));
		Assert.isTrue(File.regular(Path.join([root, "assets", "react-components", "registry.generated.ts"])));

		Fixture.runExternalMix(root, ["format", "--check-formatted", "mix.exs", "config/config.exs", "config/dev.exs"]);
		Fixture.runNodeSyntaxCheck(root, "assets/js/app.js");
		Fixture.runNodeSyntaxCheck(root, "assets/js/live-react-hooks.js");
		Fixture.runNodeSyntaxCheck(root, "assets/vite.config.mjs");

		var checkOutput = Fixture.runLiveReactTask(root, ["--check"]);

		Assert.containsString(checkOutput, "check passed; no writes occurred");

		var componentRemoveOutput = Fixture.runExternalMix(root, ["haxe.gen.live_react", "StatusPanel", "--remove", "--yes"]);

		Assert.containsString(componentRemoveOutput, "Removed StatusPanel from the static LiveReact registry");
		Assert.isTrue(File.regular(Path.join([root, "assets", "react-components", "status-panel.tsx"])));

		var removeOutput = Fixture.runLiveReactTask(root, ["--remove", "--yes"]);

		Assert.containsString(removeOutput, "Removed all currently owned PhoenixHx LiveReact state");
		Assert.isFalse(File.exists(Path.joinTwo(root, Fixture.MANIFEST)));
		Assert.containsString(File.readBang(Path.joinTwo(root, "mix.exs")), '{:live_react, path: "vendor/live_react"}');
	}
}
