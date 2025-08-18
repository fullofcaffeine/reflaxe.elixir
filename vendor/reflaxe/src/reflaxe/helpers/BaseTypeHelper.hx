// =======================================================
// * BaseTypeHelper
// =======================================================

package reflaxe.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;

using reflaxe.helpers.NameMetaHelper;

/**
	Quick static extensions to help with naming.
**/
class BaseTypeHelper {
	static final IMPL_SUFFIX = "_Impl_";
	static final FIELDS_SUFFIX = "_Fields_";

	public static function namespaces(self: BaseType): Array<String> {
		final moduleMembers = self.module.split(".");
		final moduleName = moduleMembers[moduleMembers.length - 1];
		if(moduleName != self.name && (moduleName + IMPL_SUFFIX) != self.name && (moduleName + FIELDS_SUFFIX) != self.name) {
			return moduleMembers;
		}
		return moduleMembers.slice(0, moduleMembers.length - 2);
	}

	public static function uniqueName(self: BaseType, removeSpecialSuffixes: Bool = true): String {
		final prefix = namespaces(self).join("_");
		var name = self.name;
		if(removeSpecialSuffixes) {
			name = removeNameSpecialSuffixes(name);
		}
		return (prefix.length > 0 ? (prefix + "_") : "") + (self.module == self.name ? "" : ("_" + StringTools.replace(self.module, ".", "_") + "_")) + name;
	}

	public static function globalName(self: BaseType, removeSpecialSuffixes: Bool = true): String {
		final prefix = namespaces(self).join("_");
		var name = self.name;
		if(removeSpecialSuffixes) {
			name = removeNameSpecialSuffixes(name);
		}
		return (prefix.length > 0 ? (prefix + "_") : "") + name;
	}

	public static function equals(self: BaseType, other: BaseType): Bool {
		return uniqueName(self) == uniqueName(other);
	}

	public static function removeNameSpecialSuffixes(name: String): String {
		var result = name;
		if(StringTools.endsWith(name, IMPL_SUFFIX)) {
			result = result.substring(0, result.length - IMPL_SUFFIX.length);
		}
		if(StringTools.endsWith(name, FIELDS_SUFFIX)) {
			result = result.substring(0, result.length - FIELDS_SUFFIX.length);
		}
		return result;
	}

	public static function moduleId(self: BaseType): String {
		var module = self.module;
		
		/**
		 * REFLAXE BUG FIX: Sanitize malformed EReg module path from Haxe
		 * 
		 * PROBLEM - EReg-Specific Module Corruption:
		 * EReg is the ONLY standard library class with compiler-integrated literal
		 * syntax (~/pattern/). When Haxe encounters regex literals, it goes through
		 * a special resolution path that corrupts the module name:
		 * - Expected: self.module = "EReg"
		 * - Actual: self.module = "/e_reg" (snake_case + leading slash)
		 * - Result: Attempts to write "/e_reg.ex" to filesystem root
		 * 
		 * WHY ONLY REFLAXE.ELIXIR HAS THIS BUG:
		 * We checked all other Reflaxe targets and found:
		 * - Reflaxe.CPP: Provides custom EReg in std/cxx/_std/EReg.hx → No bug
		 * - Reflaxe.Go: Provides custom EReg in src/EReg.cross.hx → No bug
		 * - Reflaxe.GDScript: Doesn't support EReg at all → No bug
		 * - Reflaxe.CSharp: Doesn't support EReg at all → No bug
		 * - Reflaxe.Elixir: Uses Haxe's standard EReg → HAS THE BUG!
		 * 
		 * We're uniquely vulnerable because we inherit Haxe's problematic EReg
		 * resolution without providing our own override.
		 * 
		 * THIS FIX - Primary Defense Layer:
		 * Remove leading "/" from module names at the earliest point in Reflaxe's
		 * pipeline. This sanitizes the corrupted module name from Haxe before it
		 * can cause filesystem errors.
		 * 
		 * WHY THIS IS THE RIGHT SOLUTION:
		 * 1. We can't fix Haxe compiler's EReg handling (out of scope)
		 * 2. Creating custom EReg would require maintaining regex implementation
		 * 3. This minimal fix solves the problem with zero side effects
		 * 4. OutputManager provides secondary defense for robustness
		 * 
		 * IMPACT:
		 * - Fixes "Read-only file system" errors when using ~/pattern/ syntax
		 * - Enables regex literals to work in Reflaxe.Elixir
		 * - No impact on any other types or correct module names
		 * 
		 * UPSTREAM STATUS:
		 * This handles a Haxe→Reflaxe interaction issue. Could be removed if:
		 * 1. Haxe fixes EReg's special resolution path
		 * 2. Reflaxe.Elixir provides custom EReg implementation
		 * 3. Reflaxe framework adds general module name sanitization
		 * 
		 * Applied by: reflaxe.elixir project
		 * Date: 2025-01-18
		 */
		if (StringTools.startsWith(module, "/")) {
			module = module.substring(1); // Remove leading slash
		}
		
		return StringTools.replace(module, ".", "_");
	}

	public static function matchesDotPath(self: BaseType, path: String): Bool {
		if(self.pack.length == 0) {
			return self.name == path;
		}
		if((self.pack.join(".") + "." + self.name) == path) {
			return true;
		}
		if((self.module + "." + self.name) == path) {
			return true;
		}
		return false;
	}

	public static function startsWithDotPath(self: BaseType, path: String): Bool {
		if(self.pack.length == 0) {
			return self.name == path;
		}

		if(StringTools.startsWith((self.pack.join(".") + "." + self.name), path)) {
			return true;
		}

		// Check for "_Fields" classes generated by Haxe.
		if(self.pack.length > 0) {
			final lastPackMember = self.pack[self.pack.length - 1];
			// Package names cannot start with underscore + uppercase letter.
			// If it does, that means it's a "fields" placeholder.
			if(lastPackMember.charCodeAt(0) == 95 && (lastPackMember.charCodeAt(1) ?? 91) <= 90) {
				// We must change `my.pack._Class._Class_Fields` to `my.pack.Class`.
				// To do this, ignore the last package member and use module name.
				if(self.pack.length <= 1 && self.module == path) {
					return true;
				}
				if(StringTools.startsWith((self.pack.slice(0, self.pack.length - 1).join(".") + "." + self.module), path)) {
					return true;
				}
			}
		}

		return false;
	}

	public static function isReflaxeExtern(self: BaseType): Bool {
		return self.isExtern || self.hasMeta(":extern");
	}
}

#end
