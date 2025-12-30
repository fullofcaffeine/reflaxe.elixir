package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr.Position;

using reflaxe.helpers.PositionHelper;

/**
 * SourceMapMarkers
 *
 * WHAT
 * - Generates stable, newline-free marker strings that can be injected into the
 *   printer output to later build Source Map v3 mappings with column fidelity.
 *
 * WHY
 * - We want expression-level mappings without rewriting the entire printer to
 *   stream through SourceMapWriter. Markers let us capture exact boundaries from
 *   the existing output and translate them into `SourceMapWriter.mapPosition/1`
 *   calls while streaming the final, marker-free output.
 *
 * HOW
 * - The printer is temporarily configured with `emit(pos)` as a callback.
 * - Each call returns a marker like `\u0001SM<id>\u0002` and stores the Position
 *   for that id.
 * - ElixirOutputIterator strips markers while feeding text into SourceMapWriter,
 *   emitting a mapping segment at every marker (plus a column-0 mapping per line).
 */
class SourceMapMarkers {
    public static inline var PREFIX = "\u0001SM";
    public static inline var SUFFIX = "\u0002";

    final positions: Array<Position>;

    // Avoid consecutive duplicates (wrapper nodes often share identical positions)
    var lastEmittedKey: Null<String> = null;

    public function new() {
        positions = [];
    }

    public function emit(pos: Position): String {
        if (pos == null) return "";

        var key = pos.getFile() + ":" + pos.line() + ":" + pos.column();
        if (lastEmittedKey == key) return "";
        lastEmittedKey = key;

        var id = positions.length;
        positions.push(pos);
        return PREFIX + id + SUFFIX;
    }

    public function getPosition(id: Int): Null<Position> {
        if (id < 0 || id >= positions.length) return null;
        return positions[id];
    }
}

#end

