package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
/**
 * HxxMode
 *
 * Template authoring modes for HEEx emission.
 *
 * - `tsx`: default strict typed authoring; raw `<% ... %>` escape hatch is forbidden.
 * - `balanced`: migration mode; legacy string templates are allowed, and raw `<% ... %>` requires explicit opt-in.
 * - `metal`: local template escape hatch that allows raw `<% ... %>`; it is not an app-wide profile.
 */
enum abstract HxxMode(String) from String to String {
	var Metal = "metal";
	var Balanced = "balanced";
	var Tsx = "tsx";
}
#end
