# Porting a “pure stdlib” Haxe program from JS → Elixir

Reflaxe.Elixir’s stdlib strategy makes it realistic to:

- write (or already have) a **portable Haxe program** using mostly the Haxe stdlib
- compile it to **Node.js** (JS target)
- then compile the *same* program to **Elixir/BEAM** (Elixir target)

This page shows a small example and explains which APIs are “portable stdlib” vs “Elixir typed externs”.

## Example: word count + JSON report (portable stdlib)

This example intentionally uses:
- `Sys.args()` (CLI args)
- `sys.io.File` (filesystem)
- `StringTools` / `String` / `Array`
- `haxe.format.JsonPrinter` (stable JSON output)

### `src/Main.hx`

```haxe
package;

import sys.io.File;
import StringTools;
import haxe.format.JsonPrinter;

class Main {
    public static function main() {
        var args = Sys.args();
        if (args.length < 1) {
            Sys.println("Usage: wordcount <path>");
            Sys.exit(1);
        }

        var path = args[0];
        var text = File.getContent(path);

        // Keep the example portable: avoid regex/EReg here.
        var normalized = StringTools.trim(text);
        normalized = StringTools.replace(normalized, "\r\n", "\n");
        normalized = StringTools.replace(normalized, "\r", "\n");
        normalized = StringTools.replace(normalized, "\n", " ");
        normalized = StringTools.replace(normalized, "\t", " ");

        var raw = normalized == "" ? [] : normalized.split(" ");
        var words = [for (w in raw) if (w != "") w];
        var counts = new Map<String, Int>();

        for (word in words) {
            var w = word.toLowerCase();
            counts.set(w, (counts.exists(w) ? counts.get(w) : 0) + 1);
        }

        // Stable ordering for deterministic output
        var keys = [for (k in counts.keys()) k];
        keys.sort(Reflect.compare);

        var result = {
            path: path,
            uniqueWords: keys.length,
            top: [for (k in keys) { word: k, count: counts.get(k) }]
        };

        Sys.println(JsonPrinter.print(result, null, "  "));
    }
}
```

Notes:
- This code is “stdlib-first”: it does not reference `elixir.*` externs.
- It’s a good fit for portability (JS↔Elixir) because it avoids Phoenix/Ecto/OTP concepts.

## Build for Node.js (JS target)

```bash
haxe -cp src -main Main -js out/wordcount.js -D nodejs
node out/wordcount.js README.md
```

## Build for Elixir (Reflaxe.Elixir target)

You typically use an `hxml` so flags don’t drift. Minimal example:

### `build-elixir.hxml`

```hxml
-cp src
-lib reflaxe.elixir
-D reflaxe_runtime
-D elixir_output=out_elixir
--macro reflaxe.elixir.CompilerInit.Start()
--main Main
```

Compile:

```bash
haxe build-elixir.hxml
```

Run (one simple way):

```bash
elixir -pa out_elixir -e "Main.main()"
```

## When stdlib portability stops being the goal

If you are writing a Phoenix app, the “best” code is usually **Elixir/Phoenix-first**:

- use typed externs for Phoenix/Ecto/OTP surfaces (e.g. `phoenix.*`, `ecto.*`, `elixir.DateTime`, etc.)
- keep stdlib use focused on local pure logic (validation, parsing, small transforms)

Practical reasons:
- Phoenix’s primary data shapes are structs/atoms/tagged tuples; typed externs model that directly.
- Writing your LiveViews like Phoenix expects makes the generated Elixir easier to reason about.

See:
- `docs/04-api-reference/STANDARD_LIBRARY_HANDLING.md`
- `docs/02-user-guide/PHOENIX_INTEGRATION.md`
- `docs/02-user-guide/TYPE_SAFE_PHOENIX_ABSTRACTIONS.md`
