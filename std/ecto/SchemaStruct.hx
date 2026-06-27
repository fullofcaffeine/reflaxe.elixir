package ecto;

#if (elixir || reflaxe_runtime)
import elixir.Kernel;

/**
 * Typed helpers for constructing Ecto schema structs.
 *
 * WHAT: Provides a Haxe-typed boundary around Elixir's `Kernel.struct/1`.
 * WHY: App code should not need ad hoc `cast Kernel.struct(Schema)` calls when
 * building empty schema values for changesets.
 * HOW: Centralizes the unavoidable term-to-schema cast in PhoenixHx std code
 * and inlines away so generated Elixir stays the handwritten shape:
 * `Kernel.struct(User)`.
 */
@:native("PhoenixHx.Ecto.SchemaStruct")
extern class SchemaStruct {
	extern inline public static function empty<T>(schema:Class<T>):T {
		return cast Kernel.struct(schema);
	}
}
#end
