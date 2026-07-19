package phoenix_live_react_tooling;

import elixir.ElixirMacro;
import elixir.ElixirMap;
import elixir.ElixirString;
import elixir.Enum;
import elixir.Kernel;
import elixir.Path;
import elixir.Regex;
import elixir.types.Term;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactComponent;

/**
 * Closed LiveReact component registry and hand-owned starter rendering.
 *
 * The manifest deliberately records only import identity. Prop and event
 * contracts remain ordinary Haxe and TypeScript source, so this module does
 * not grow into a second cross-language schema system.
 */
@:keep
@:native("HaxePhoenixLiveReact.Registry")
class LiveReactRegistry {
	static inline final COMPONENT_NAME_PATTERN = "^[A-Z][A-Za-z0-9]*$";
	static inline final EXPORT_NAME_PATTERN = "^[A-Za-z_$][A-Za-z0-9_$]*$";
	static inline final MODULE_PATH_PATTERN = "^\\./[A-Za-z0-9][A-Za-z0-9_./-]*$";
	static inline final APP_NAME_PATTERN = "^[a-z][a-z0-9_]*$";
	static inline final HXX_INTERPOLATION = "$";

	public static function component(name:String, modulePath:Null<String> = null, exportName:Null<String> = null):LiveReactComponent {
		var normalized:LiveReactComponent = {
			name: name,
			modulePath: modulePath == null ? defaultModulePath(name) : modulePath,
			exportName: exportName == null ? name + "Boundary" : exportName
		};
		validateComponent(normalized);
		return normalized;
	}

	public static function componentsFromManifest(value:Term):Array<LiveReactComponent> {
		if (!Kernel.isList(value))
			Kernel.raiseValue("LiveReact manifest components must be a JSON array. No writes occurred.");
		var entries:Array<Term> = value;
		var components = Enum.map(entries, function(entry:Term):LiveReactComponent {
			if (!Kernel.isMap(entry))
				Kernel.raiseValue("each LiveReact component entry must be a JSON object. No writes occurred.");
			var keys:Array<String> = ElixirMap.keysTerm(entry);
			if (Enum.sort(keys) != ["export", "module", "name"])
				Kernel.raiseValue("each LiveReact component entry must contain exactly name, module, and export. No writes occurred.");
			var name = ElixirMap.get(entry, "name");
			var modulePath = ElixirMap.get(entry, "module");
			var exportName = ElixirMap.get(entry, "export");
			if (!Kernel.isBinary(name) || !Kernel.isBinary(modulePath) || !Kernel.isBinary(exportName))
				Kernel.raiseValue("LiveReact component name, module, and export must be strings. No writes occurred.");
			return component(Kernel.toString(name), Kernel.toString(modulePath), Kernel.toString(exportName));
		});
		var normalized = normalizeComponents(components);
		if (componentNames(components) != componentNames(normalized))
			Kernel.raiseValue("LiveReact manifest components must be sorted by name. No writes occurred.");
		return normalized;
	}

	public static function normalizeComponents(components:Array<LiveReactComponent>):Array<LiveReactComponent> {
		Enum.each(components, validateComponent);
		var sorted = Enum.sortBy(components, function(value:LiveReactComponent):String return value.name);
		Enum.reduce(sorted, null, function(value:LiveReactComponent, previous:Null<String>):Null<String> {
			if (previous == value.name)
				Kernel.raise('duplicate LiveReact component name ${value.name}. No writes occurred. Component names are static registry identities.');
			return value.name;
		});
		return sorted;
	}

	public static function toManifestTerms(components:Array<LiveReactComponent>):Array<Term> {
		return Enum.map(normalizeComponents(components), function(value:LiveReactComponent):Term {
			var entry = ElixirMap.new_();
			entry = ElixirMap.putTerm(entry, "name", value.name);
			entry = ElixirMap.putTerm(entry, "module", value.modulePath);
			return ElixirMap.putTerm(entry, "export", value.exportName);
		});
	}

	public static function renderRegistryFile(components:Array<LiveReactComponent>):String {
		var normalized = normalizeComponents(components);
		var imports = Enum.map(normalized, function(value:LiveReactComponent):String {
			return 'import {${value.exportName} as ${value.name}Component} from "${value.modulePath}"';
		});
		var entries = Enum.map(normalized, function(value:LiveReactComponent):String return '  ${value.name}: ${value.name}Component,');
		return joinSections([
			['/* ${IntegrationCore.GENERATED_SIGNATURE} */'],
			imports,
			["export const componentRegistry = {"],
			entries,
			[
				"} as const",
				"",
				"export type ComponentName = keyof typeof componentRegistry",
				"",
				"export default componentRegistry"
			]
		]);
	}

	public static function renderHaxeWrapper(appName:String, value:LiveReactComponent):String {
		validateAppName(appName);
		validateComponent(value);
		var packageName = appName + "_hx.components.live_react";
		var nativeModule = ElixirMacro.camelize(appName) + "Web.ReactIslands." + value.name;
		return joinLines([
			'package $packageName;',
			"",
			"import phoenix.live_react.LiveReact;",
			"import phoenix.types.Assigns;",
			"",
			'private typedef ${value.name}Assigns = {',
			"\tvar id:String;",
			"\tvar title:String;",
			"}",
			"",
			"/**",
			' * Hand-owned typed Phoenix boundary for the fixed ${value.name} React island.',
			" *",
			" * Keep the component name and SSR posture static. Extend this closed assigns",
			" * type alongside the trusted TypeScript boundary when adding public props.",
			" */",
			'@:native("$nativeModule")',
			"@:component",
			'class ${value.name}Island {',
			"\t@:component",
			'\tpublic static function render(assigns:Assigns<${value.name}Assigns>):String {',
			'\t\treturn <div class="react-island-host">',
			"\t\t\t<LiveReact.react",
			"\t\t\t\tid=" + HXX_INTERPOLATION + "{assigns.id}",
			'\t\t\t\tname="${value.name}"',
			"\t\t\t\ttitle=" + HXX_INTERPOLATION + "{assigns.title}",
			"\t\t\t\tssr=" + HXX_INTERPOLATION + "{false}",
			"\t\t\t/>",
			"\t\t</div>;",
			"\t}",
			"}"
		]);
	}

	/** Managed app-local component required by strict HXX in Haxe root layouts. */
	public static function renderReloadWrapper(appName:String):String {
		validateAppName(appName);
		var packageName = appName + "_hx.components.live_react";
		var nativeModule = reloadComponentModule(appName);
		return joinLines([
			'// ${IntegrationCore.GENERATED_SIGNATURE}',
			'package $packageName;',
			"",
			"import elixir.types.Term;",
			"import phoenix.live_react.LiveReactReload;",
			"import phoenix.types.Assigns;",
			"import phoenix.types.Slot;",
			"",
			"private typedef LiveReactViteAssetsAssigns = {",
			"\tvar assets:Array<String>;",
			"\t@:slot var inner_block:Slot<Term>;",
			"}",
			"",
			"/**",
			" * Generated app-local strict-HXX boundary for stock LiveReact development assets.",
			" * The wrapper forwards the complete assigns/default-slot payload unchanged.",
			" */",
			'@:native("$nativeModule")',
			"@:component",
			"class LiveReactAssets {",
			"\t@:component",
			"\tpublic static function vite_assets(assigns:Assigns<LiveReactViteAssetsAssigns>):Term {",
			"\t\treturn LiveReactReload.vite_assets(assigns);",
			"\t}",
			"}"
		]);
	}

	public static function renderBoundary(value:LiveReactComponent):String {
		validateComponent(value);
		var slug = componentSlug(value.name);
		return joinLines([
			'import {${value.name}} from "./$slug"',
			"",
			'export type ${value.name}RawProps = Record<string, unknown>',
			"",
			'interface ${value.name}Input {',
			"  readonly title: string",
			"}",
			"",
			'const publicInputKeys = new Set(["title"])',
			"const nativeBridgeKeys = new Set([",
			'  "pushEvent",',
			'  "pushEventTo",',
			'  "handleEvent",',
			'  "removeHandleEvent",',
			'  "upload",',
			'  "uploadTo",',
			"])",
			"",
			'function decode${value.name}Input(value: Record<string, unknown>): ${value.name}Input {',
			'  if (Object.keys(value).length !== 1 || typeof value.title !== "string" || value.title.trim() === "") {',
			'    throw new Error("${value.name} expects exactly one non-empty string prop: title")',
			"  }",
			"  return {title: value.title}",
			"}",
			"",
			"/**",
			" * Trusted stock LiveReact adapter. It narrows capabilities for a first-party",
			" * component; it is not a sandbox for untrusted React code.",
			" */",
			'export function ${value.exportName}(raw: ${value.name}RawProps) {',
			"  try {",
			"    const publicInput: Record<string, unknown> = {}",
			"    for (const [key, candidate] of Object.entries(raw)) {",
			"      if (nativeBridgeKeys.has(key)) continue",
			'      if (!publicInputKeys.has(key)) throw new Error("Unexpected ${value.name} input: " + key)',
			"      publicInput[key] = candidate",
			"    }",
			"",
			'    const input = decode${value.name}Input(publicInput)',
			'    return <${value.name} {...input} />',
			"  } catch (error) {",
			'    const message = error instanceof Error ? error.message : "Unknown React boundary error"',
			"    return (",
			'      <section role="alert" data-live-react-boundary="error">',
			'        <strong>${value.name} is unavailable.</strong>',
			"        <span>{message}</span>",
			"      </section>",
			"    )",
			"  }",
			"}"
		]);
	}

	public static function renderInnerComponent(value:LiveReactComponent):String {
		validateComponent(value);
		var slug = componentSlug(value.name);
		return joinLines([
			'export interface ${value.name}Props {',
			"  readonly title: string",
			"}",
			"",
			"/** Hand-owned, unstyled starter. Apply the host application's visual system here. */",
			'export function ${value.name}({title}: ${value.name}Props) {',
			"  return (",
			'    <section data-react-island="$slug">',
			'      <p aria-hidden="true">React island</p>',
			"      <h2>{title}</h2>",
			"    </section>",
			"  )",
			"}"
		]);
	}

	public static function defaultModulePath(name:String):String {
		validateName(name);
		return "./" + componentSlug(name) + "-boundary";
	}

	public static function componentSlug(name:String):String {
		validateName(name);
		return ElixirString.replace(ElixirMacro.underscore(name), "_", "-");
	}

	public static function wrapperRelativePath(appName:String, value:LiveReactComponent):String {
		validateAppName(appName);
		return Path.join([
			"src_haxe",
			appName + "_hx",
			"components",
			"live_react",
			value.name + "Island.hx"
		]);
	}

	public static function reloadWrapperRelativePath(appName:String):String {
		validateAppName(appName);
		return Path.join(["src_haxe", appName + "_hx", "components", "live_react", "LiveReactAssets.hx"]);
	}

	public static function reloadComponentModule(appName:String):String {
		validateAppName(appName);
		return ElixirMacro.camelize(appName) + "Web.ReactIslands.LiveReactAssets";
	}

	public static function boundaryRelativePath(value:LiveReactComponent):String {
		return Path.join(["assets", "react-components", componentSlug(value.name) + "-boundary.tsx"]);
	}

	public static function innerRelativePath(value:LiveReactComponent):String {
		return Path.join(["assets", "react-components", componentSlug(value.name) + ".tsx"]);
	}

	public static function boundaryCandidates(value:LiveReactComponent):Array<String> {
		validateComponent(value);
		var relative = ElixirString.replacePrefix(value.modulePath, "./", "");
		var extension = Path.extname(relative);
		return extension == "" ? Enum.map([".tsx", ".ts", ".jsx", ".js"], function(suffix:String):String return relative + suffix) : [relative];
	}

	static function validateComponent(value:LiveReactComponent):Void {
		validateName(value.name);
		if (!Regex.match(Regex.compileBang(MODULE_PATH_PATTERN), value.modulePath)
			|| ElixirString.contains(value.modulePath, "//")
			|| Enum.member(Path.split(value.modulePath), ".."))
			Kernel.raise('invalid LiveReact component module ${Kernel.inspect(value.modulePath)}. Expected a closed project-relative import such as ./preference-studio-boundary. No writes occurred.');
		if (!Regex.match(Regex.compileBang(EXPORT_NAME_PATTERN), value.exportName))
			Kernel.raise('invalid LiveReact component export ${Kernel.inspect(value.exportName)}. Expected a JavaScript identifier. No writes occurred.');
	}

	static function validateName(name:String):Void {
		if (!Regex.match(Regex.compileBang(COMPONENT_NAME_PATTERN), name))
			Kernel.raise('invalid LiveReact component name ${Kernel.inspect(name)}. Expected a static PascalCase identifier such as PreferenceStudio. No writes occurred.');
	}

	public static function validateAppName(appName:String):Void {
		if (!Regex.match(Regex.compileBang(APP_NAME_PATTERN), appName))
			Kernel.raise('invalid Mix application name ${Kernel.inspect(appName)}. Expected a lowercase underscore identifier. No writes occurred.');
	}

	static function componentNames(components:Array<LiveReactComponent>):Array<String> {
		return Enum.map(components, function(value:LiveReactComponent):String return value.name);
	}

	static function joinSections(sections:Array<Array<String>>):String {
		var nonEmpty = Enum.filter(sections, function(section:Array<String>):Bool return section.length != 0);
		var lines = Enum.reduce(nonEmpty, [], function(section:Array<String>, current:Array<String>):Array<String> {
			return current.length == 0 ? section : Enum.concatTwo(Enum.concatTwo(current, [""]), section);
		});
		return joinLines(lines);
	}

	static function joinLines(lines:Array<String>):String {
		return Enum.join(Enum.concatTwo(lines, [""]), "\n");
	}
}
