# VS Code Debugging (Source Maps)

Reflaxe.Elixir can emit Source Map v3 files (`.ex.map`) alongside generated Elixir (`.ex`) so you can jump from a runtime Elixir location back to the original Haxe code.

This guide documents the current workflow for VS Code. (ElixirLS and VS Code do not automatically consume `.ex.map` files yet; you use the provided Mix task as the bridge.)

## Prerequisites

- VS Code
- VS Code extensions:
  - **ElixirLS** (for Elixir navigation, stacktraces, and Phoenix work)
  - **Haxe** (vshaxe) (for Haxe navigation)
- The VS Code `code` CLI available in your shell (`code --version`)

## 1) Enable `.ex.map` emission

Add this define to the Haxe build that generates your server-side Elixir:

```hxml
-D source_map_enabled
```

Then compile as usual (for example via `mix compile` in a Phoenix project using the included Mix integration).

You should see sibling files in your output directory:

- `lib/my_app/some_module.ex`
- `lib/my_app/some_module.ex.map`

## 2) Map an Elixir runtime position back to Haxe

When you see an Elixir stacktrace pointing at a generated file, run:

```bash
mix haxe.source_map lib/my_app/some_module.ex 45 0
```

Notes:
- `LINE` is 1-based.
- `COLUMN` is 0-based.
- If the stacktrace doesn’t include a column, use `0` (you still get a correct file/line mapping).

## 3) Open the mapped location in VS Code

Use the `goto` output format to produce a VS Code-compatible `file:line:column` string (1-based column):

```bash
code --goto "$(mix haxe.source_map lib/my_app/some_module.ex 45 0 --format goto)"
```

This works for both directions:

- Elixir → Haxe (generated `.ex` input)
- Haxe → Elixir (source `.hx` input; reverse mode is auto-detected for `.hx`)

Example (Haxe → Elixir):

```bash
code --goto "$(mix haxe.source_map src_haxe/my_app/some_module/MyMod.hx 20 0 --format goto)"
```

## 4) Optional: add a VS Code task (interactive prompts)

Create `.vscode/tasks.json` in your Phoenix project:

```jsonc
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Reflaxe.Elixir: Open mapped Haxe location",
      "type": "shell",
      "command": "bash",
      "args": [
        "-lc",
        "code --goto \"$(mix haxe.source_map ${input:genFile} ${input:genLine} ${input:genCol} --format goto)\""
      ],
      "problemMatcher": []
    }
  ],
  "inputs": [
    { "id": "genFile", "type": "promptString", "description": "Generated .ex file path" },
    { "id": "genLine", "type": "promptString", "description": "Line (1-based)" },
    { "id": "genCol", "type": "promptString", "description": "Column (0-based; use 0 if unknown)", "default": "0" }
  ]
}
```

Then run it via the Command Palette: “Tasks: Run Task” → “Reflaxe.Elixir: Open mapped Haxe location”.

## Troubleshooting

- **No source map found**
  - Ensure you compiled with `-D source_map_enabled`.
  - Use `mix haxe.source_map --list-maps` to see which maps are available.
- **Mapping looks “off” by one column**
  - Source Map v3 columns are 0-based; editors often display 1-based columns. Use `--format goto` for editor jumps.
- **Shipping `.map` files**
  - Source maps can reveal source file names/paths. Treat them as debug artifacts unless you explicitly want them in a production build.

