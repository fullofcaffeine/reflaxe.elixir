package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;

using reflaxe.helpers.NullableMetaAccessHelper;

/**
 * EnumPatternContext: Metadata-based enum pattern context tracking
 * 
 * WHY: Solves the architectural problem of context loss between compilation phases.
 * When PatternMatchingCompiler processes enum patterns, it creates mappings that
 * are lost by the time VariableCompiler runs. This causes incorrect variable
 * resolution (g_array instead of g_param_0).
 * 
 * WHAT: Provides a clean abstraction for tracking enum pattern context using
 * Haxe's metadata system. This follows the established Reflaxe pattern used
 * for tracking unused variables (-reflaxe.unused).
 * 
 * HOW: 
 * - Adds metadata to TVars when they're created in enum pattern contexts
 * - Provides checking methods for later compilation phases
 * - Maintains contextual information across compiler phases
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles enum pattern context
 * - Open/Closed: Can be extended for other pattern types
 * - Persistent Context: Metadata survives compilation phases
 * - Clean API: Simple mark/check interface
 * 
 * EDGE CASES:
 * - Handles null metadata gracefully
 * - Works with nested enum patterns
 * - Compatible with existing enumExtractionVars system
 * 
 * @see documentation/ENUM_PATTERN_CONTEXT_SOLUTION.md
 */
/**
 * Information about an enum pattern extraction
 */
typedef EnumPatternInfo = {
	/** The enum field name (constructor) */
	var enumField: String;
	
	/** The parameter index in the constructor */
	var paramIndex: Int;
	
	/** The extraction variable name (e.g., g_param_0) */
	var extractionVar: String;
	
	/** Optional: The original variable name before extraction */
	var ?originalVar: String;
}

@:nullSafety(Off)
class EnumPatternContext {
	
	/**
	 * Metadata name for marking enum pattern variables
	 */
	static inline final ENUM_PATTERN_META = "-reflaxe.enumPattern";
	
	/**
	 * Mark a TVar as being from an enum pattern extraction
	 * 
	 * WHY: Provides persistent context that survives compilation phases
	 * WHAT: Adds metadata with enum pattern information to the TVar
	 * HOW: Uses Haxe's metadata system to attach contextual data
	 * 
	 * @param tvar The type variable to mark
	 * @param info Context information about the enum pattern
	 * @param pos Position for metadata
	 */
	public static function markEnumPatternVar(tvar: TVar, info: EnumPatternInfo, pos: Position): Void {
		#if debug_enum_pattern_context
		trace('[EnumPatternContext] Marking TVar ${tvar.name} as enum pattern extraction');
		trace('[EnumPatternContext] Info: field=${info.enumField}, index=${info.paramIndex}, extraction=${info.extractionVar}');
		#end
		
		// Create metadata parameters
		var params: Array<Expr> = [
			{ expr: EConst(CString(info.enumField)), pos: pos },
			{ expr: EConst(CInt(Std.string(info.paramIndex))), pos: pos },
			{ expr: EConst(CString(info.extractionVar)), pos: pos }
		];
		
		// Add original variable name if available
		if (info.originalVar != null) {
			params.push({ expr: EConst(CString(info.originalVar)), pos: pos });
		}
		
		// Add metadata to TVar
		tvar.meta.maybeAdd(ENUM_PATTERN_META, params, pos);
		
		#if debug_enum_pattern_context
		trace('[EnumPatternContext] ✓ Metadata added to ${tvar.name}');
		#end
	}
	
	/**
	 * Check if a TVar is from an enum pattern extraction
	 * 
	 * @param tvar The type variable to check
	 * @return True if this variable is from enum pattern extraction
	 */
	public static function isEnumPatternVar(tvar: TVar): Bool {
		if (tvar.meta == null) return false;
		
		var result = tvar.meta.maybeHas(ENUM_PATTERN_META);
		
		#if debug_enum_pattern_context
		if (result) {
			trace('[EnumPatternContext] TVar ${tvar.name} IS an enum pattern variable');
		}
		#end
		
		return result;
	}
	
	/**
	 * Get the extraction variable name for an enum pattern TVar
	 * 
	 * WHY: Allows VariableCompiler to get the correct extraction variable
	 * WHAT: Retrieves the stored extraction variable name from metadata
	 * HOW: Parses the metadata parameters to extract the variable name
	 * 
	 * @param tvar The type variable to get extraction info for
	 * @return The extraction variable name (e.g., g_param_0) or null
	 */
	public static function getExtractionVar(tvar: TVar): Null<String> {
		if (tvar.meta == null) {
			#if debug_enum_pattern_context
			trace('[EnumPatternContext] No metadata on TVar: ${tvar.name} (id: ${tvar.id})');
			#end
			return null;
		}
		
		// CRITICAL: Use non-destructive metadata access
		// extract() REMOVES metadata, causing subsequent calls to fail
		// Instead, use get() to access metadata without removing it
		var metadataArray = tvar.meta.get();
		for (meta in metadataArray) {
			if (meta.name == ENUM_PATTERN_META) {
				var params = meta.params;
				if (params != null && params.length >= 3) {
					// Extract the extraction variable name (3rd parameter)
					var extractionVar = switch(params[2].expr) {
						case EConst(CString(s)): s;
						case _: null;
					}
					
					#if debug_enum_pattern_context
					if (extractionVar != null) {
						trace('[EnumPatternContext] Found extraction var: ${extractionVar} for ${tvar.name} (id: ${tvar.id})');
					}
					#end
					
					return extractionVar;
				}
			}
		}
		
		#if debug_enum_pattern_context
		trace('[EnumPatternContext] No enum pattern metadata found on ${tvar.name} (id: ${tvar.id})');
		#end
		
		return null;
	}
	
	/**
	 * Get complete enum pattern information from a TVar
	 * 
	 * @param tvar The type variable to get info for
	 * @return Complete enum pattern information or null
	 */
	public static function getEnumPatternInfo(tvar: TVar): Null<reflaxe.elixir.helpers.EnumPatternInfo> {
		if (tvar.meta == null) return null;
		
		// CRITICAL: Use non-destructive metadata access
		// Don't use extract() which removes the metadata
		var metadataArray = tvar.meta.get();
		for (meta in metadataArray) {
			if (meta.name == ENUM_PATTERN_META) {
				var params = meta.params;
				if (params != null && params.length >= 3) {
					// Extract information from metadata
					var info: reflaxe.elixir.helpers.EnumPatternInfo = {
						enumField: switch(params[0].expr) {
							case EConst(CString(s)): s;
							case _: "";
						},
						paramIndex: switch(params[1].expr) {
							case EConst(CInt(i)): Std.parseInt(i);
							case _: -1;
						},
						extractionVar: switch(params[2].expr) {
							case EConst(CString(s)): s;
							case _: "";
						},
						originalVar: params.length > 3 ? switch(params[3].expr) {
							case EConst(CString(s)): s;
							case _: null;
						} : null
					};
					
					#if debug_enum_pattern_context
					trace('[EnumPatternContext] Retrieved info for ${tvar.name}:');
					trace('  - enumField: ${info.enumField}');
					trace('  - paramIndex: ${info.paramIndex}');
					trace('  - extractionVar: ${info.extractionVar}');
					trace('  - originalVar: ${info.originalVar}');
					#end
					
					return info;
				}
			}
		}
		
		return null;
	}
	
	/**
	 * Clear enum pattern metadata from a TVar
	 * 
	 * @param tvar The type variable to clear metadata from
	 */
	public static function clearEnumPatternMeta(tvar: TVar): Void {
		if (tvar.meta == null) return;
		
		tvar.meta.remove(ENUM_PATTERN_META);
		
		#if debug_enum_pattern_context
		trace('[EnumPatternContext] Cleared metadata from ${tvar.name}');
		#end
	}
}

#end