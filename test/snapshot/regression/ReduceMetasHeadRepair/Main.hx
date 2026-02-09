import elixir.ElixirMap;

typedef PresenceMeta = {
    var name: String;
    var onlineAt: Int;
}

typedef PresenceEntry = {
    var metas: Array<PresenceMeta>;
}

class Main {
    static function main() {
        var presences: Map<String, PresenceEntry> = [
            "user-a" => { metas: [{ name: "A", onlineAt: 1 }] },
            "user-b" => { metas: [{ name: "B", onlineAt: 2 }] }
        ];

        var names: Array<String> = [];
        var keys: Array<String> = cast ElixirMap.keys(presences);
        for (key in keys) {
            var entry: Null<PresenceEntry> = ElixirMap.getWithDefault(presences, key, null);
            if (entry != null && entry.metas != null && entry.metas.length > 0) {
                var meta = entry.metas[0];
                // Consume fields so lowering must treat `meta` as a struct-like value.
                names.push(meta.name + ":" + Std.string(meta.onlineAt));
            }
        }

        trace(names.join(","));
    }
}
