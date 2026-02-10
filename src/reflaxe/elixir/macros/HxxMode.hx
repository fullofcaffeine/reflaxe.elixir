package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

/**
 * HxxMode
 *
 * Template authoring modes for HEEx emission.
 *
 * - `balanced`: default; raw `<% ... %>` requires explicit opt-in.
 * - `tsx`: strict typed authoring; raw `<% ... %>` escape hatch is forbidden.
 * - `metal`: allow raw `<% ... %>` (discouraged; close to the metal).
 */
enum abstract HxxMode(String) from String to String {
    var Metal = "metal";
    var Balanced = "balanced";
    var Tsx = "tsx";
}

#end

