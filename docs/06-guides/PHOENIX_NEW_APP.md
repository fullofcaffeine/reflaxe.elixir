# Phoenix (New App) — Greenfield Setup

This guide shows how to start a brand-new Phoenix project where you can author **selected modules in Haxe** and compile them to idiomatic Elixir.

If you already have an existing Phoenix app, use `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`.

## Goal

- Keep Phoenix conventions and tooling (Mix, releases, Ecto, LiveView).
- Add Haxe **incrementally**: start with one module, then expand.
- Generate Elixir code that looks hand-written.

## Option A (recommended): scaffold via the project generator

If you have Haxe + Node installed, you can generate a ready-to-run Phoenix+Haxe project in one go:

```bash
# From an empty directory where you want the project folder created:
npm init -y
npm install --save-dev lix
npx lix scope create

# Install the generator (latest GitHub release tag)
# If this fails (no `curl` / GitHub rate limit), pick a tag from the Releases page and set it manually.
REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*\"tag_name\":[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p' | head -n 1)"
npx lix install "github:fullofcaffeine/reflaxe.elixir#${REFLAXE_ELIXIR_TAG}"

# Generate a Phoenix app (add --skip-install if you want to run installs manually)
npx lix run reflaxe.elixir create my_app --type phoenix --no-interactive

cd my_app
mix setup
mix phx.server
```

If you pass `--skip-install` (or installs fail), run the installs manually:

```bash
cd my_app
npm install
npx lix scope create
# If this fails (no `curl` / GitHub rate limit), pick a tag from the Releases page and set it manually.
REFLAXE_ELIXIR_TAG="$(curl -fsSL https://api.github.com/repos/fullofcaffeine/reflaxe.elixir/releases/latest | sed -n 's/.*\"tag_name\":[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p' | head -n 1)"
npx lix install "github:fullofcaffeine/reflaxe.elixir#${REFLAXE_ELIXIR_TAG}"
npx lix download
mix setup
mix phx.server
```

## Option B: create a Phoenix app (normal Phoenix) + add Haxe (gradual adoption)

Use Phoenix as you normally would:

```bash
mix phx.new my_app
cd my_app
```

Confirm the baseline app runs:

```bash
mix setup
mix phx.server
```

## 2) Add Reflaxe.Elixir (follow the gradual adoption guide)

From here, greenfield and “add to existing” are the same workflow.

Continue with:

- `docs/06-guides/PHOENIX_GRADUAL_ADOPTION.md`

## Recommended Template Starting Points

If you prefer a ready-made example to copy:

- `examples/03-phoenix-app/` — minimal Phoenix app authored in Haxe
- `examples/todo-app/` — end-to-end Phoenix LiveView + Ecto + Playwright E2E
