package phoenix_hx_todo_hx.live;

import StringTools;
import elixir.ElixirMap;
import elixir.types.Term;
import phoenix_hx_todo_hx.contexts.Accounts;
import phoenix_hx_todo_hx.contexts.Todos;
import phoenix_hx_todo_hx.data.User;
import phoenix.LiveSocket;
import phoenix.Phoenix.EventParams;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountParams;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Session;
import phoenix.Phoenix.Socket;
import phoenix_hx_todo_hx.live.AppLiveTypes.AppLiveAssigns;
import plug.CSRFProtection;

@:native("PhoenixHxTodoWeb.AppLive")
@:liveview
class AppLive {
	public static function mount(_params:MountParams, session:Session, socket:Socket<AppLiveAssigns>):MountResult<AppLiveAssigns> {
		var user = currentUser(session);
		var assignedSocket = user == null ? assignSignedOut(socket) : assignSignedIn(socket, user);
		return Ok(assignedSocket);
	}

	public static function handleEvent(event:String, params:EventParams, socket:Socket<AppLiveAssigns>):HandleEventResult<AppLiveAssigns> {
		var live:LiveSocket<AppLiveAssigns> = socket;

		return switch (event) {
			case "update_form":
				NoReply(live.merge({
					title_input: stringParam(params, "title"),
					notes_input: stringParam(params, "notes")
				}));
			case "create_todo":
				createTodo(params, live);
			case "toggle_todo":
				toggleTodo(params, live);
			case "delete_todo":
				deleteTodo(params, live);
			default:
				NoReply(live);
		}
	}

	public static function render(assigns:AppLiveAssigns):String {
		return <div id="phoenixhx-root" class="phoenixhx-page" phx-hook="PhoenixHxTodoFocus">
			<if ${!assigns.authenticated}>
				<main class="login-shell">
					<section class="login-hero panel">
						<div class="login-copy">
							<span class="eyebrow">RailsHx to PhoenixHx</span>
							<h1>Same todo room, Phoenix rules.</h1>
							<p>
								This page keeps the RailsHx todo app's guest-entry workflow and warm editorial shell,
								then swaps Rails controllers, ERB partials, Devise, and Turbo Streams for Phoenix LiveView events.
							</p>
						</div>
						<div class="credential-card">
							<span>Seeded demo</span>
							<strong>guest@example.test</strong>
							<em>Use the guest button for this first Phoenix slice.</em>
						</div>
					</section>

					<section class="login-panel panel" id="phoenixhx-session-panel">
						<span class="eyebrow">Demo session</span>
						<h2>Open the converted board.</h2>
						<p>
							RailsHx delegates the real sample to Devise. This PhoenixHx slice keeps auth deliberately small:
							a controller action creates a Plug session, then the LiveView consumes the derived session map.
						</p>
						<if ${assigns.status != null}>
							<div class="status" role="status">${assigns.status}</div>
						</if>
						<form action="/auth/demo" method="post">
							<input type="hidden" name="_csrf_token" value=${assigns.csrf_token} />
							<input type="hidden" name="name" value="Guest Workspace" />
							<input type="hidden" name="email" value="guest@example.test" />
							<button type="submit" class="primary-action" data-testid="continue-guest" data-phoenixhx-autofocus>
								Continue as guest
							</button>
						</form>
					</section>
				</main>
			<else>
				<main class="todo-shell">
					<header class="app-topbar">
						<div class="brand-mark">
							<span>PHX</span>
							<div>
								<strong>PhoenixHx Todo</strong>
								<em>LiveView session active</em>
							</div>
						</div>
						<nav class="topbar-links" aria-label="Conversion map">
							<a href="#open-work">Open work</a>
							<a href="#conversion-notes">Rails to Phoenix</a>
						</nav>
						<div class="session-chip">
							<span>${assigns.current_user_name}</span>
							<small>${assigns.current_user_email}</small>
							<form action="/auth/logout" method="post">
								<input type="hidden" name="_csrf_token" value=${assigns.csrf_token} />
								<button type="submit" class="secondary-action">Log out</button>
							</form>
						</div>
					</header>

					<section class="hero">
						<div class="panel hero-copy">
							<span class="eyebrow">RailsHx sample, Phoenix implementation</span>
							<h1>Typed Phoenix, live BEAM state.</h1>
							<p>
								The RailsHx source renders ERB and Turbo Streams from Haxe. This port renders HEEx
								from inline HXX and persists mutations through Ecto contexts.
							</p>
						</div>
						<aside class="panel stat-panel" aria-label="Todo stats">
							<div class="stat">
								<strong>${assigns.stats.open_count}</strong>
								<span>open tasks</span>
							</div>
							<div class="stat">
								<strong>${assigns.stats.typed_column_count}</strong>
								<span>typed fields</span>
							</div>
						</aside>
					</section>

					<section class="workspace">
						<div class="panel composer-card">
							<h2>Add a task</h2>
							<form phx-submit="create_todo" phx-change="update_form" class="todo-form" data-testid="todo-form">
								<p class="form-owner-note">New tasks will be assigned to ${assigns.current_user_name}.</p>
								<label>
									<span>What should ship next?</span>
									<input type="text" name="title" value=${assigns.title_input} placeholder="Write the Phoenix LiveView port" required data-phoenixhx-autofocus />
								</label>
								<label>
									<span>Why does it matter?</span>
									<textarea name="notes" rows="3" placeholder="Add a short implementation note">${assigns.notes_input}</textarea>
								</label>
								<button type="submit" class="primary-action">Add task</button>
							</form>
							<if ${assigns.status != null}>
								<div class="status" role="status">${assigns.status}</div>
							</if>
						</div>

						<div id="open-work" class="panel open-work-card" tabindex="-1">
							<h2>Open work</h2>
							<div id="phoenixhx-todo-list" class="todo-list-frame">
								<if ${assigns.todos.length == 0}>
									<div class="empty-state">No open tasks. Serene, but suspicious.</div>
								<else>
									<ul class="todo-list">
										<for ${todo in assigns.todos}>
											<li class=${todo.row_class} data-testid="todo-item">
												<span class="todo-dot" aria-hidden="true"></span>
												<div class="todo-body">
													<span>${todo.title}</span>
													<if ${todo.notes != ""}>
														<p class="todo-notes">${todo.notes}</p>
													</if>
													<small>Owner: ${todo.owner}</small>
												</div>
												<div class="todo-actions">
													<button type="button" class="icon-action" phx-click="toggle_todo" phx-value-id=${Std.string(todo.id)}>
														${todo.completed ? "Reopen" : "Done"}
													</button>
													<button type="button" class="icon-action danger" phx-click="delete_todo" phx-value-id=${Std.string(todo.id)}>
														Delete
													</button>
												</div>
											</li>
										</for>
									</ul>
								</else>
								</if>
							</div>
						</div>
					</section>

					<section id="conversion-notes" class="panel conversion-panel">
						<span class="eyebrow">Conversion notes</span>
						<h2>The Rails API is not being emulated.</h2>
						<div class="crosswalk-grid">
							<div><strong>ActiveRecord model</strong><span>Ecto schema + context boundary</span></div>
							<div><strong>ActionController action</strong><span>Controller session action + LiveView callbacks</span></div>
							<div><strong>HHX ERB partial</strong><span>Inline HXX function/component shape</span></div>
							<div><strong>Turbo Stream mutation</strong><span>LiveView event diff over Ecto-backed state</span></div>
						</div>
					</section>
				</main>
			</else>
			</if>
		</div>;
	}

	static function createTodo(params:Term, socket:LiveSocket<AppLiveAssigns>):HandleEventResult<AppLiveAssigns> {
		var title = stringParam(params, "title");
		var notes = stringParam(params, "notes");
		if (StringTools.trim(title) == "") {
			return NoReply(socket.assign(_.status, "Add a title before creating a task."));
		}

		var user = Accounts.getUser(socket.assigns.current_user_id);
		if (user == null)
			return NoReply(socket.assign(_.status, "Sign in again before creating a task."));

		return switch (Todos.createForUser(user, title, notes)) {
			case Ok(_):
				NoReply(refreshTodos(socket.merge({title_input: "", notes_input: ""}), "Task added through Ecto and Phoenix LiveView."));
			case Error(_):
				NoReply(socket.assign(_.status, "Could not create that task."));
		};
	}

	static function toggleTodo(params:Term, socket:LiveSocket<AppLiveAssigns>):HandleEventResult<AppLiveAssigns> {
		var id = intParam(params, "id");
		var didToggle = Todos.toggleForUser(socket.assigns.current_user_id, id);
		if (didToggle) {
			return NoReply(refreshTodos(socket, "Updated through Ecto and a LiveView diff."));
		}
		return NoReply(socket.assign(_.status, "Could not update that task."));
	}

	static function deleteTodo(params:Term, socket:LiveSocket<AppLiveAssigns>):HandleEventResult<AppLiveAssigns> {
		var id = intParam(params, "id");
		var didDelete = Todos.deleteForUser(socket.assigns.current_user_id, id);
		if (didDelete) {
			return NoReply(refreshTodos(socket, "Deleted from the database through the Todos context."));
		}
		return NoReply(socket.assign(_.status, "Could not delete that task."));
	}

	static function assignSignedOut(socket:Socket<AppLiveAssigns>):Socket<AppLiveAssigns> {
		var owner = "Guest Workspace";
		return socket.assign({
			authenticated: false,
			current_user_id: null,
			current_user_name: owner,
			current_user_email: "guest@example.test",
			csrf_token: CSRFProtection.get_csrf_token(),
			title_input: "",
			notes_input: "",
			todos: [],
			status: "Sign in or continue as guest to open the PhoenixHx board.",
			stats: TodoState.stats([])
		});
	}

	static function assignSignedIn(socket:Socket<AppLiveAssigns>, user:User):Socket<AppLiveAssigns> {
		var todos = Todos.viewItemsForUser(user);
		return socket.assign({
			authenticated: true,
			current_user_id: user.id,
			current_user_name: User.displayName(user),
			current_user_email: user.email,
			csrf_token: CSRFProtection.get_csrf_token(),
			title_input: "",
			notes_input: "",
			todos: todos,
			status: "Phoenix session active. Todos are persisted through Ecto.",
			stats: TodoState.stats(todos)
		});
	}

	static function currentUser(session:Session):Null<User> {
		var userId:Term = ElixirMap.get(session, "user_id");
		return userId != null ? Accounts.getUser(cast userId) : null;
	}

	static function refreshTodos(socket:LiveSocket<AppLiveAssigns>, status:String):LiveSocket<AppLiveAssigns> {
		var user = Accounts.getUser(socket.assigns.current_user_id);
		if (user == null)
			return socket.assign(_.status, "Sign in again to reload tasks.");
		var todos = Todos.viewItemsForUser(user);
		return socket.merge({todos: todos, stats: TodoState.stats(todos), status: status});
	}

	static function stringParam(params:Term, key:String):String {
		var value:Null<String> = cast Reflect.field(params, key);
		return value != null ? value : "";
	}

	static function intParam(params:Term, key:String):Int {
		var value = stringParam(params, key);
		var parsed = Std.parseInt(value);
		return parsed != null ? parsed : 0;
	}
}
