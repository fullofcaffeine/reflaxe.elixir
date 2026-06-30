# RailsHx Conversion Inventory

This report is generated from RailsHx todo source paths and conservative mapping rules.
It is an example-local report and fixture, not a Phoenix compatibility layer and not the architecture for a general migration compiler.

RailsHx source reference: [reflaxe.ruby/examples/todoapp_rails](https://github.com/fullofcaffeine/reflaxe.ruby/tree/main/examples/todoapp_rails)

## Summary

- Source artifacts classified: 47
- Deterministic mappings: 41
- Human-decision mappings: 6
- Already covered by the PhoenixHx example: 36

## Deterministic Mapping Rules

| RailsHx convention | PhoenixHx target | Notes |
| --- | --- | --- |
| `models/*.hx` | Ecto schema plus context module | Direct for resource data; associations and ownership still need review. |
| `migrations/*.hx` | Ecto migration | Direct for table/column/index shape; auth-library generated tables need review. |
| `controllers/TodosController.hx` | LiveView events plus context calls | Direct when the endpoint is an interactive HTML workflow. |
| `controllers/SessionsController.hx` | Phoenix controller session edge | Direct for demo login/logout; production auth remains a choice. |
| `views/Todo*.hx` | Inline HXX in LiveView/components | Direct for presentational structure; keep Phoenix assigns/events idiomatic. |
| `shared/*.hx` | Shared Haxe constants | Direct when they name DOM ids, hooks, or event names. |
| `client/*.hx` | Genes-compiled LiveView hook bootstrap | Direct only for progressive behavior, not HTML rendering. |
| Rails tests and Playwright specs | Haxe-authored ExUnit plus thin Playwright smoke | Direct at the user-flow level, not line-for-line assertion ports. |

## Human Decision Areas

| Area | Why deterministic conversion stops | PhoenixHx direction |
| --- | --- | --- |
| Devise/Warden | Auth libraries carry lifecycle, schema, mailer, token, and security policy choices. | Use demo Phoenix session for the example; choose `phx.gen.auth` or another production auth stack explicitly. |
| Turbo Streams | Broadcast granularity and DOM ownership differ from LiveView. | Use LiveView diffs and Phoenix.PubSub when cross-session updates matter. |
| Optional chat panel | Product scope and persistence/broadcast semantics need a decision. | Add a focused PubSub-backed LiveView panel only if it improves the example. |
| Optional user management | Admin UX, authorization, and account lifecycle policy are product choices. | Add a separate LiveView route/panel with explicit authorization assumptions. |
| Rails callbacks/helpers | Phoenix has different extension points. | Map to context functions, changesets, plugs, or LiveView lifecycle callbacks by intent. |

## Artifact Inventory

| RailsHx artifact | Source kind | PhoenixHx target | Mapping | Status |
| --- | --- | --- | --- | --- |
| [Main.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/Main.hx) | Rails app bootstrap | Phoenix OTP application and router entrypoints | deterministic | implemented |
| [README.md](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/README.md) | reference docs | Phoenix example README plus conversion docs | deterministic | implemented |
| [app/auth/UserAuth.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/app/auth/UserAuth.hx) | Rails auth helper | Phoenix session/on_mount auth boundary or production auth package | human decision | partially implemented |
| [assets/stylesheets/application.css](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/assets/stylesheets/application.css) | stylesheet | assets/css/app.css | deterministic | implemented |
| [build-client.hxml](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/build-client.hxml) | build config | Phoenix example build/test/client hxml files | deterministic | partially implemented |
| [build-e2e.hxml](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/build-e2e.hxml) | build config | Phoenix example build/test/client hxml files | deterministic | partially implemented |
| [client/TodoClient.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/client/TodoClient.hx) | Rails browser client | src_haxe/client/Boot.hx | deterministic | implemented |
| [controllers/ChatMessagesController.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/controllers/ChatMessagesController.hx) | ActionController optional panel | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx and contexts/ChatMessages.hx | deterministic | implemented |
| [controllers/SessionsController.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/controllers/SessionsController.hx) | ActionController session | src_haxe/phoenix_hx_todo_hx/controllers/SessionController.hx | deterministic | implemented |
| [controllers/TodosController.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/controllers/TodosController.hx) | ActionController CRUD | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx and contexts/Todos.hx | deterministic | implemented |
| [controllers/UsersController.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/controllers/UsersController.hx) | ActionController optional panel | Phoenix route or LiveView panel for user management | human decision | deferred optional panel |
| [e2e/todo_hooks.ts](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/e2e/todo_hooks.ts) | browser spec | src_shared/shared/TodoHooks.hx | deterministic | partially implemented |
| [e2e/todoapp.spec.ts](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/e2e/todoapp.spec.ts) | browser spec | e2e/railshx_port.spec.ts | deterministic | partially implemented |
| [e2e_haxe/TodoappBrowserSpec.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/e2e_haxe/TodoappBrowserSpec.hx) | browser spec | Playwright smoke plus optional future Haxe browser spec | deterministic | partially implemented |
| [migrations/AddDeviseToUsers.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/migrations/AddDeviseToUsers.hx) | Devise migration | Phoenix session auth or production auth package migration | human decision | deferred auth choice |
| [migrations/CreateChatMessages.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/migrations/CreateChatMessages.hx) | ActiveRecord migration | src_haxe/phoenix_hx_todo_hx/migrations/CreateChatMessages.hx | deterministic | implemented |
| [migrations/CreateTodos.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/migrations/CreateTodos.hx) | ActiveRecord migration | src_haxe/phoenix_hx_todo_hx/migrations/CreateTodos.hx | deterministic | implemented |
| [migrations/UpdateTodos.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/migrations/UpdateTodos.hx) | ActiveRecord migration | src_haxe/phoenix_hx_todo_hx/migrations/CreateTodos.hx | deterministic | implemented |
| [migrations/UpdateUsers.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/migrations/UpdateUsers.hx) | ActiveRecord migration | src_haxe/phoenix_hx_todo_hx/migrations/CreateUsers.hx | deterministic | implemented |
| [models/ChatMessage.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/models/ChatMessage.hx) | ActiveRecord model | src_haxe/phoenix_hx_todo_hx/data/ChatMessage.hx and contexts/ChatMessages.hx | deterministic | implemented |
| [models/Todo.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/models/Todo.hx) | ActiveRecord model | src_haxe/phoenix_hx_todo_hx/data/Todo.hx and contexts/Todos.hx | deterministic | implemented |
| [models/User.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/models/User.hx) | ActiveRecord model | src_haxe/phoenix_hx_todo_hx/data/User.hx and contexts/Accounts.hx | deterministic | implemented |
| [rails/config/routes_rails_owned.rb](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/rails/config/routes_rails_owned.rb) | Rails routes | Phoenix RouterDsl routes and live_session | deterministic | implemented |
| [rails/test/controllers/routes_test.rb](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/rails/test/controllers/routes_test.rb) | Rails test | Haxe-authored ExUnit or Playwright coverage | deterministic | implemented |
| [rails/test/controllers/todos_controller_test.rb](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/rails/test/controllers/todos_controller_test.rb) | Rails test | src_haxe/test/web/TodoPersistenceTest.hx | deterministic | implemented |
| [rails/test/models/chat_message_test.rb](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/rails/test/models/chat_message_test.rb) | Rails test | src_haxe/test/web/ChatPanelTest.hx | deterministic | implemented |
| [rails/test/models/todo_test.rb](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/rails/test/models/todo_test.rb) | Rails test | src_haxe/test/live/TodoStateTest.hx | deterministic | implemented |
| [rails/test/models/user_test.rb](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/rails/test/models/user_test.rb) | Rails test | Haxe-authored ExUnit account tests | human decision | deferred optional panel |
| [shared/TodoHooks.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/shared/TodoHooks.hx) | shared hook constants | src_shared/shared/TodoHooks.hx | deterministic | implemented |
| [src_haxe/routes/AppRoutes.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/src_haxe/routes/AppRoutes.hx) | Rails routes | src_haxe/PhoenixHxTodoRouter.hx | deterministic | implemented |
| [src_haxe/routes/Routes.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/src_haxe/routes/Routes.hx) | Rails routes | src_haxe/PhoenixHxTodoRouter.hx | deterministic | implemented |
| [test_haxe/controllers/TodosHaxeRequestTest.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/test_haxe/controllers/TodosHaxeRequestTest.hx) | Rails test | src_haxe/test/web/TodoPersistenceTest.hx | deterministic | implemented |
| [test_haxe/models/TodoHaxeTest.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/test_haxe/models/TodoHaxeTest.hx) | Rails test | src_haxe/test/live/TodoStateTest.hx | deterministic | implemented |
| [tools/ExportTodoHooks.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/tools/ExportTodoHooks.hx) | Rails support tool | Phoenix example support script only if still needed | human decision | not ported |
| [views/AppTopBarView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/AppTopBarView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/ApplicationLayoutView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/ApplicationLayoutView.hx) | HHX view | lib/phoenix_hx_todo_web/components/layouts/*.heex | deterministic | implemented |
| [views/ChatMessageView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/ChatMessageView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/ChatPanelView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/ChatPanelView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/DeviseLoginView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/DeviseLoginView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/TodoCardView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/TodoCardView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/TodoComposerView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/TodoComposerView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/TodoDashboardView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/TodoDashboardView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/TodoFormView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/TodoFormView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/TodoIndexView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/TodoIndexView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/TodoListView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/TodoListView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/TodoSummaryView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/TodoSummaryView.hx) | HHX view | src_haxe/phoenix_hx_todo_hx/live/AppLive.hx | deterministic | implemented |
| [views/UserManagementView.hx](https://github.com/fullofcaffeine/reflaxe.ruby/blob/main/examples/todoapp_rails/views/UserManagementView.hx) | HHX view | LiveView component or route | human decision | deferred optional panel |

## Tooling Shape

This report illustrates useful inventory evidence for the todo fixture. A future general migration compiler should live outside this example and use a typed Evidence IR, decision records, migration plans, coexistence topology, and verification receipts:

1. Inventory RailsHx files by path convention and declared metadata.
2. Emit a report that separates deterministic mappings from decision-required mappings.
3. Generate PhoenixHx stubs only from an approved migration plan with enough type information.
4. Require explicit user choices for auth, Turbo/PubSub behavior, optional panels, and data lifecycle policy.
5. Keep any Rails-to-Phoenix adapter layer optional and granular, never implicit.

The todo app may validate that future tool, but it should not define the tool's architecture or contain app-specific conversion rules.

Regenerate locally with:

```bash
RAILSHX_TODO_SOURCE=/path/to/reflaxe.ruby/examples/todoapp_rails \
  node examples/17-railshx-to-phoenixhx-todo/tools/rails_hx_inventory.js \
  > examples/17-railshx-to-phoenixhx-todo/docs/CONVERSION_INVENTORY.md
```
