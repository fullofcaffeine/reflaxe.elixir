package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * ModuleFieldMetadataRegistry
 *
 * WHAT
 * - Captures metadata/imports declared on module-level fields (KModuleFields carriers)
 *   during build-macro execution and exposes them later to compiler phases.
 *
 * WHY
 * - Haxe can remove extern module-level fields during typing/filter passes.
 * - When that happens, metadata attached to those fields (for example `@:router`,
 *   `@:routes`, `@:native`) is no longer visible via `classType.statics`.
 * - We need a stable source of truth so module-level declarations remain usable
 *   without requiring non-extern placeholder bodies.
 *
 * HOW
 * - `capture()` is called from a global build macro (`AnnotatedModuleEnumerator`).
 * - We store field metadata + local import table by module path.
 * - Compiler phases query this registry to merge metadata and resolve short type refs.
 */
typedef ModuleFieldImportData = {
	var explicitImports:Map<String, String>;
	var wildcardImports:Array<String>;
}

class ModuleFieldMetadataRegistry {
	static var metadataByModulePath:Map<String, Array<MetadataEntry>> = new Map();
	static var importsByModulePath:Map<String, ModuleFieldImportData> = new Map();

	public static function capture(classType:ClassType, fields:Array<Field>):Void {
		if (classType == null || fields == null)
			return;

		switch (classType.kind) {
			case KModuleFields(_):
				captureMetadata(classType, fields);
				captureImports(classType);
			default:
		}
	}

	public static function extractMetadata(classType:ClassType, primaryName:String, alternateName:String):Array<MetadataEntry> {
		if (classType == null)
			return [];

		var source = findMetadata(classType);
		if (source == null || source.length == 0)
			return [];

		var matches:Array<MetadataEntry> = [];
		for (entry in source) {
			if (entry == null)
				continue;
			if (metadataNameMatches(entry.name, primaryName, alternateName))
				matches.push(entry);
		}
		return matches;
	}

	public static function hasMetadata(classType:ClassType, primaryName:String, alternateName:String):Bool {
		return extractMetadata(classType, primaryName, alternateName).length > 0;
	}

	public static function resolveImportedTypePath(classType:ClassType, typePath:String):String {
		if (classType == null || typePath == null || typePath.length == 0)
			return typePath;

		var importData = findImports(classType);
		if (importData != null) {
			var direct = importData.explicitImports.get(typePath);
			if (direct != null && direct.length > 0)
				return direct;

			var aliasResolved = resolveAliasPath(typePath, importData.explicitImports);
			if (aliasResolved != null && aliasResolved.length > 0)
				return aliasResolved;

			if (typePath.indexOf(".") == -1 && importData.wildcardImports != null) {
				for (wildcardPath in importData.wildcardImports) {
					var candidate = wildcardPath + "." + typePath;
					if (canResolveType(candidate))
						return candidate;
				}
			}
		}

		if (typePath.indexOf(".") == -1 && classType.module != null && classType.module.length > 0) {
			var moduleCandidate = classType.module + "." + typePath;
			if (canResolveType(moduleCandidate))
				return moduleCandidate;
			if (classType.pack != null && classType.pack.length > 0 && classType.module.indexOf(".") == -1) {
				var qualifiedModuleCandidate = classType.pack.join(".") + "." + classType.module + "." + typePath;
				if (canResolveType(qualifiedModuleCandidate))
					return qualifiedModuleCandidate;
			}
		}

		// Same-package fallback for short references (`PageController`).
		if (typePath.indexOf(".") == -1 && classType.pack != null && classType.pack.length > 0) {
			var packageCandidate = classType.pack.join(".") + "." + typePath;
			if (canResolveType(packageCandidate))
				return packageCandidate;
		}

		return typePath;
	}

	static function captureMetadata(classType:ClassType, fields:Array<Field>):Void {
		var entries:Array<MetadataEntry> = [];
		for (field in fields) {
			if (field == null || field.meta == null)
				continue;
			for (entry in field.meta) {
				if (entry == null)
					continue;
				entries.push({
					name: entry.name,
					params: entry.params != null ? entry.params.copy() : [],
					pos: entry.pos
				});
			}
		}

		if (entries.length == 0)
			return;

		for (key in registryKeys(classType)) {
			metadataByModulePath.set(key, entries);
		}
	}

	static function captureImports(classType:ClassType):Void {
		var explicit = new Map<String, String>();
		var wildcards:Array<String> = [];

		var imports = Context.getLocalImports();
		if (imports != null) {
			for (importExpr in imports) {
				if (importExpr == null || importExpr.path == null || importExpr.path.length == 0)
					continue;
				var path = importPathToString(importExpr.path);
				if (path == null || path.length == 0)
					continue;

				switch (importExpr.mode) {
					case IAsName(alias):
						if (alias != null && alias.length > 0)
							explicit.set(alias, path);
					case IAll:
						if (wildcards.indexOf(path) == -1)
							wildcards.push(path);
					case INormal:
						var importedName = importExpr.path[importExpr.path.length - 1].name;
						if (importedName != null && importedName.length > 0)
							explicit.set(importedName, path);
				}
			}
		}

		var data:ModuleFieldImportData = {
			explicitImports: explicit,
			wildcardImports: wildcards
		};
		for (key in registryKeys(classType)) {
			importsByModulePath.set(key, data);
		}
	}

	static inline function resolveModulePath(classType:ClassType):String {
		if (classType.module != null && classType.module.length > 0)
			return classType.module;
		return classType.pack.length > 0 ? classType.pack.join(".") + "." + classType.name : classType.name;
	}

	static inline function resolveClassPath(classType:ClassType):String {
		return classType.pack.length > 0 ? classType.pack.join(".") + "." + classType.name : classType.name;
	}

	static function registryKeys(classType:ClassType):Array<String> {
		var keys:Array<String> = [];
		addRegistryKey(keys, resolveClassPath(classType));
		addRegistryKey(keys, resolveModulePath(classType));
		if (classType.pack != null && classType.pack.length > 0 && classType.module != null && classType.module.length > 0
			&& classType.module.indexOf(".") == -1) {
			addRegistryKey(keys, classType.pack.join(".") + "." + classType.module);
		}
		return keys;
	}

	static function addRegistryKey(keys:Array<String>, key:String):Void {
		if (key == null || key.length == 0)
			return;
		if (keys.indexOf(key) == -1)
			keys.push(key);
	}

	static function findMetadata(classType:ClassType):Null<Array<MetadataEntry>> {
		for (key in registryKeys(classType)) {
			var entries = metadataByModulePath.get(key);
			if (entries != null && entries.length > 0)
				return entries;
		}
		return null;
	}

	static function findImports(classType:ClassType):Null<ModuleFieldImportData> {
		for (key in registryKeys(classType)) {
			var data = importsByModulePath.get(key);
			if (data != null)
				return data;
		}
		return null;
	}

	static function importPathToString(path:Array<{name:String, pos:Position}>):String {
		var parts:Array<String> = [];
		for (segment in path) {
			if (segment == null || segment.name == null || segment.name.length == 0)
				continue;
			parts.push(segment.name);
		}
		return parts.length > 0 ? parts.join(".") : null;
	}

	static function metadataNameMatches(actual:String, primaryName:String, alternateName:String):Bool {
		if (actual == primaryName || actual == alternateName)
			return true;

		if (primaryName != null && primaryName.length > 1 && primaryName.charAt(0) == ":" && actual == primaryName.substr(1))
			return true;
		if (alternateName != null && alternateName.length > 1 && alternateName.charAt(0) == ":" && actual == alternateName.substr(1))
			return true;

		return false;
	}

	static function resolveAliasPath(typePath:String, explicitImports:Map<String, String>):Null<String> {
		if (typePath == null || typePath.length == 0 || explicitImports == null)
			return null;

		var dotIndex = typePath.indexOf(".");
		if (dotIndex <= 0)
			return null;

		var alias = typePath.substr(0, dotIndex);
		if (!explicitImports.exists(alias))
			return null;

		var importedPath = explicitImports.get(alias);
		if (importedPath == null || importedPath.length == 0)
			return null;

		var remainder = typePath.substr(dotIndex + 1);
		return remainder != null && remainder.length > 0 ? importedPath + "." + remainder : importedPath;
	}

	static function canResolveType(typePath:String):Bool {
		if (typePath == null || typePath.length == 0)
			return false;
		try {
			Context.getType(typePath);
			return true;
		} catch (_:Dynamic) {
			return false;
		}
	}
}
#end
