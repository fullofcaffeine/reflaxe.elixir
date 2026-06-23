#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const sourceRepoUrl =
  "https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails";
const sourceBlobUrl =
  "https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails";

const implementedTargets = {
  "models/Todo.hx": "src_haxe/phoenix_hx_todo_hx/data/Todo.hx and contexts/Todos.hx",
  "models/User.hx": "src_haxe/phoenix_hx_todo_hx/data/User.hx and contexts/Accounts.hx",
  "migrations/CreateTodos.hx": "src_haxe/phoenix_hx_todo_hx/migrations/CreateTodos.hx",
  "migrations/UpdateTodos.hx": "src_haxe/phoenix_hx_todo_hx/migrations/CreateTodos.hx",
  "migrations/UpdateUsers.hx": "src_haxe/phoenix_hx_todo_hx/migrations/CreateUsers.hx",
  "controllers/SessionsController.hx": "src_haxe/phoenix_hx_todo_hx/controllers/SessionController.hx",
  "controllers/TodosController.hx": "src_haxe/phoenix_hx_todo_hx/live/AppLive.hx and contexts/Todos.hx",
  "views/AppTopBarView.hx": "src_haxe/phoenix_hx_todo_hx/live/AppLive.hx",
  "views/ApplicationLayoutView.hx": "lib/phoenix_hx_todo_web/components/layouts/*.heex",
  "views/DeviseLoginView.hx": "src_haxe/phoenix_hx_todo_hx/live/AppLive.hx",
  "views/TodoCardView.hx": "src_haxe/phoenix_hx_todo_hx/live/AppLive.hx",
  "views/TodoComposerView.hx": "src_haxe/phoenix_hx_todo_hx/live/AppLive.hx",
  "views/TodoDashboardView.hx": "src_haxe/phoenix_hx_todo_hx/live/AppLive.hx",
  "views/TodoFormView.hx": "src_haxe/phoenix_hx_todo_hx/live/AppLive.hx",
  "views/TodoIndexView.hx": "src_haxe/phoenix_hx_todo_hx/live/AppLive.hx",
  "views/TodoListView.hx": "src_haxe/phoenix_hx_todo_hx/live/AppLive.hx",
  "views/TodoSummaryView.hx": "src_haxe/phoenix_hx_todo_hx/live/AppLive.hx",
  "assets/stylesheets/application.css": "assets/css/app.css",
  "client/TodoClient.hx": "src_haxe/client/Boot.hx",
  "shared/TodoHooks.hx": "src_haxe/shared/TodoHooks.hx",
  "src_haxe/routes/AppRoutes.hx": "src_haxe/PhoenixHxTodoRouter.hx",
  "src_haxe/routes/Routes.hx": "src_haxe/PhoenixHxTodoRouter.hx",
  "e2e/todoapp.spec.ts": "e2e/railshx_port.spec.ts",
  "e2e/todo_hooks.ts": "src_haxe/shared/TodoHooks.hx",
  "test_haxe/controllers/TodosHaxeRequestTest.hx": "src_haxe/test/web/TodoPersistenceTest.hx",
  "test_haxe/models/TodoHaxeTest.hx": "src_haxe/test/live/TodoStateTest.hx",
  "rails/test/controllers/todos_controller_test.rb": "src_haxe/test/web/TodoPersistenceTest.hx",
  "rails/test/models/todo_test.rb": "src_haxe/test/live/TodoStateTest.hx"
};

const knownOptionalTargets = {
  "models/ChatMessage.hx": "Phoenix context plus PubSub-backed LiveView panel",
  "controllers/ChatMessagesController.hx": "LiveView event handlers plus Phoenix.PubSub broadcasts",
  "views/ChatPanelView.hx": "LiveView component or nested LiveView",
  "views/ChatMessageView.hx": "LiveView component",
  "migrations/CreateChatMessages.hx": "Ecto migration if chat panel ships",
  "controllers/UsersController.hx": "Phoenix route or LiveView panel for user management",
  "views/UserManagementView.hx": "LiveView component or route",
  "rails/test/models/chat_message_test.rb": "Haxe-authored ExUnit context tests if chat ships",
  "rails/test/models/user_test.rb": "Haxe-authored ExUnit account tests",
  "app/auth/UserAuth.hx": "Phoenix session/on_mount auth boundary or production auth package"
};

function usage() {
  return [
    "Usage: node tools/rails_hx_inventory.js --source <path-to-reflaxe.ruby/examples/todoapp_rails>",
    "",
    "The tool only reads source files and writes a Markdown report to stdout.",
    "It classifies artifacts by RailsHx path conventions and does not generate Phoenix code."
  ].join("\n");
}

function parseArgs(argv) {
  const args = { source: process.env.RAILSHX_TODO_SOURCE || "" };
  for (let index = 2; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--source") {
      args.source = argv[index + 1] || "";
      index += 1;
    } else if (arg === "--help" || arg === "-h") {
      args.help = true;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return args;
}

function walk(rootDir) {
  const entries = [];
  for (const name of fs.readdirSync(rootDir).sort()) {
    const fullPath = path.join(rootDir, name);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      entries.push.apply(entries, walk(fullPath));
    } else {
      entries.push(fullPath);
    }
  }
  return entries;
}

function isInventoryFile(relativePath) {
  return (
    /\.(hx|rb|ts|css|md|hxml)$/.test(relativePath) &&
    !relativePath.startsWith(".") &&
    !relativePath.includes("/tmp/")
  );
}

function classNameFrom(relativePath) {
  return path.basename(relativePath).replace(/\.[^.]+$/, "");
}

function classify(relativePath) {
  const baseName = classNameFrom(relativePath);

  if (relativePath === "README.md") {
    return entry("reference docs", "Phoenix example README plus conversion docs", "deterministic", "implemented");
  }
  if (relativePath.endsWith(".hxml")) {
    return entry("build config", "Phoenix example build/test/client hxml files", "deterministic", "partially implemented");
  }
  if (relativePath === "Main.hx") {
    return entry("Rails app bootstrap", "Phoenix OTP application and router entrypoints", "deterministic", "implemented");
  }
  if (relativePath === "assets/stylesheets/application.css") {
    return entry("stylesheet", "Phoenix asset CSS", "deterministic", "implemented");
  }
  if (relativePath.startsWith("models/")) {
    if (baseName === "ChatMessage") {
      return entry("ActiveRecord model", "Ecto schema plus chat context", "human decision", "deferred optional panel");
    }
    return entry("ActiveRecord model", "Ecto schema plus context API", "deterministic", "implemented");
  }
  if (relativePath.startsWith("migrations/")) {
    if (baseName.indexOf("Chat") >= 0) {
      return entry("ActiveRecord migration", "Ecto migration for optional chat table", "human decision", "deferred optional panel");
    }
    if (baseName.indexOf("Devise") >= 0) {
      return entry("Devise migration", "Phoenix session auth or production auth package migration", "human decision", "deferred auth choice");
    }
    return entry("ActiveRecord migration", "Ecto migration", "deterministic", "implemented");
  }
  if (relativePath.startsWith("controllers/")) {
    if (baseName === "TodosController") {
      return entry("ActionController CRUD", "LiveView events plus context commands", "deterministic", "implemented");
    }
    if (baseName === "SessionsController") {
      return entry("ActionController session", "Phoenix controller session edge", "deterministic", "implemented");
    }
    if (baseName === "UsersController" || baseName === "ChatMessagesController") {
      return entry("ActionController optional panel", "LiveView route/component plus context", "human decision", "deferred optional panel");
    }
    return entry("ActionController", "Phoenix controller or LiveView boundary", "human decision", "needs review");
  }
  if (relativePath.startsWith("views/")) {
    if (baseName.indexOf("Chat") >= 0 || baseName === "UserManagementView") {
      return entry("HHX view", "Optional LiveView component or route", "human decision", "deferred optional panel");
    }
    return entry("HHX view", "Inline HXX rendered by LiveView/components", "deterministic", "implemented");
  }
  if (relativePath.startsWith("client/")) {
    return entry("Rails browser client", "Phoenix LiveView hook bootstrapped through Genes", "deterministic", "implemented");
  }
  if (relativePath.startsWith("shared/")) {
    return entry("shared hook constants", "shared Haxe hook constants", "deterministic", "implemented");
  }
  if (relativePath.startsWith("src_haxe/routes/") || relativePath === "rails/config/routes_rails_owned.rb") {
    return entry("Rails routes", "Phoenix RouterDsl routes and live_session", "deterministic", "implemented");
  }
  if (relativePath.startsWith("e2e/") || relativePath.startsWith("e2e_haxe/")) {
    return entry("browser spec", "Playwright smoke plus optional future Haxe browser spec", "deterministic", "partially implemented");
  }
  if (relativePath.startsWith("test_haxe/") || relativePath.startsWith("rails/test/")) {
    if (relativePath.indexOf("chat") >= 0 || relativePath.indexOf("user") >= 0) {
      return entry("Rails test", "Haxe-authored ExUnit if optional panel ships", "human decision", "deferred optional panel");
    }
    return entry("Rails test", "Haxe-authored ExUnit or Playwright coverage", "deterministic", "implemented");
  }
  if (relativePath.startsWith("app/auth/")) {
    return entry("Rails auth helper", "Phoenix session/on_mount auth boundary", "human decision", "partially implemented");
  }
  if (relativePath.startsWith("tools/")) {
    return entry("Rails support tool", "Phoenix example support script only if still needed", "human decision", "not ported");
  }
  return entry("unclassified", "Manual review", "human decision", "needs review");
}

function entry(sourceKind, phoenixTarget, conversionKind, status) {
  return { sourceKind, phoenixTarget, conversionKind, status };
}

function targetFor(relativePath, classification) {
  return (
    implementedTargets[relativePath] ||
    knownOptionalTargets[relativePath] ||
    classification.phoenixTarget
  );
}

function markdownLink(relativePath) {
  return `[${relativePath}](${sourceBlobUrl}/${relativePath})`;
}

function makeReport(rootDir) {
  const files = walk(rootDir)
    .map((fullPath) => path.relative(rootDir, fullPath).split(path.sep).join("/"))
    .filter(isInventoryFile)
    .sort();

  const rows = files.map((relativePath) => {
    const classification = classify(relativePath);
    return {
      relativePath,
      sourceKind: classification.sourceKind,
      phoenixTarget: targetFor(relativePath, classification),
      conversionKind: classification.conversionKind,
      status: classification.status
    };
  });

  const deterministicRows = rows.filter((row) => row.conversionKind === "deterministic");
  const decisionRows = rows.filter((row) => row.conversionKind !== "deterministic");
  const implementedRows = rows.filter((row) => row.status === "implemented");

  const lines = [];
  lines.push("# RailsHx Conversion Inventory");
  lines.push("");
  lines.push("This report is generated from RailsHx todo source paths and conservative mapping rules.");
  lines.push("It is a prototype for future migration tooling, not a Phoenix compatibility layer.");
  lines.push("");
  lines.push(`RailsHx source reference: [reflaxe.ruby/examples/todoapp_rails](${sourceRepoUrl})`);
  lines.push("");
  lines.push("## Summary");
  lines.push("");
  lines.push(`- Source artifacts classified: ${rows.length}`);
  lines.push(`- Deterministic mappings: ${deterministicRows.length}`);
  lines.push(`- Human-decision mappings: ${decisionRows.length}`);
  lines.push(`- Already covered by the PhoenixHx example: ${implementedRows.length}`);
  lines.push("");
  lines.push("## Deterministic Mapping Rules");
  lines.push("");
  lines.push("| RailsHx convention | PhoenixHx target | Notes |");
  lines.push("| --- | --- | --- |");
  lines.push("| `models/*.hx` | Ecto schema plus context module | Direct for resource data; associations and ownership still need review. |");
  lines.push("| `migrations/*.hx` | Ecto migration | Direct for table/column/index shape; auth-library generated tables need review. |");
  lines.push("| `controllers/TodosController.hx` | LiveView events plus context calls | Direct when the endpoint is an interactive HTML workflow. |");
  lines.push("| `controllers/SessionsController.hx` | Phoenix controller session edge | Direct for demo login/logout; production auth remains a choice. |");
  lines.push("| `views/Todo*.hx` | Inline HXX in LiveView/components | Direct for presentational structure; keep Phoenix assigns/events idiomatic. |");
  lines.push("| `shared/*.hx` | Shared Haxe constants | Direct when they name DOM ids, hooks, or event names. |");
  lines.push("| `client/*.hx` | Genes-compiled LiveView hook bootstrap | Direct only for progressive behavior, not HTML rendering. |");
  lines.push("| Rails tests and Playwright specs | Haxe-authored ExUnit plus thin Playwright smoke | Direct at the user-flow level, not line-for-line assertion ports. |");
  lines.push("");
  lines.push("## Human Decision Areas");
  lines.push("");
  lines.push("| Area | Why deterministic conversion stops | PhoenixHx direction |");
  lines.push("| --- | --- | --- |");
  lines.push("| Devise/Warden | Auth libraries carry lifecycle, schema, mailer, token, and security policy choices. | Use demo Phoenix session for the example; choose `phx.gen.auth` or another production auth stack explicitly. |");
  lines.push("| Turbo Streams | Broadcast granularity and DOM ownership differ from LiveView. | Use LiveView diffs and Phoenix.PubSub when cross-session updates matter. |");
  lines.push("| Optional chat panel | Product scope and persistence/broadcast semantics need a decision. | Add a focused PubSub-backed LiveView panel only if it improves the example. |");
  lines.push("| Optional user management | Admin UX, authorization, and account lifecycle policy are product choices. | Add a separate LiveView route/panel with explicit authorization assumptions. |");
  lines.push("| Rails callbacks/helpers | Phoenix has different extension points. | Map to context functions, changesets, plugs, or LiveView lifecycle callbacks by intent. |");
  lines.push("");
  lines.push("## Artifact Inventory");
  lines.push("");
  lines.push("| RailsHx artifact | Source kind | PhoenixHx target | Mapping | Status |");
  lines.push("| --- | --- | --- | --- | --- |");
  for (const row of rows) {
    lines.push(
      `| ${markdownLink(row.relativePath)} | ${row.sourceKind} | ${row.phoenixTarget} | ${row.conversionKind} | ${row.status} |`
    );
  }
  lines.push("");
  lines.push("## Tooling Shape");
  lines.push("");
  lines.push("A future converter can keep this pipeline deterministic and reviewable:");
  lines.push("");
  lines.push("1. Inventory RailsHx files by path convention and declared metadata.");
  lines.push("2. Emit a report that separates deterministic mappings from decision-required mappings.");
  lines.push("3. Generate PhoenixHx stubs only for deterministic mappings with enough type information.");
  lines.push("4. Require explicit user choices for auth, Turbo/PubSub behavior, optional panels, and data lifecycle policy.");
  lines.push("5. Keep any Rails-to-Phoenix adapter layer optional and granular, never implicit.");
  lines.push("");
  lines.push("Regenerate locally with:");
  lines.push("");
  lines.push("```bash");
  lines.push("node examples/17-railshx-to-phoenixhx-todo/tools/rails_hx_inventory.js \\");
  lines.push("  --source ../haxe.ruby/examples/todoapp_rails \\");
  lines.push("  > examples/17-railshx-to-phoenixhx-todo/docs/CONVERSION_INVENTORY.md");
  lines.push("```");
  lines.push("");
  return lines.join("\n");
}

function main() {
  const args = parseArgs(process.argv);
  if (args.help) {
    console.log(usage());
    return;
  }
  if (!args.source) {
    throw new Error(`${usage()}\n\nMissing --source or RAILSHX_TODO_SOURCE.`);
  }
  const rootDir = path.resolve(process.cwd(), args.source);
  if (!fs.existsSync(rootDir) || !fs.statSync(rootDir).isDirectory()) {
    throw new Error(`RailsHx source directory does not exist: ${args.source}`);
  }
  console.log(makeReport(rootDir));
}

try {
  main();
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
