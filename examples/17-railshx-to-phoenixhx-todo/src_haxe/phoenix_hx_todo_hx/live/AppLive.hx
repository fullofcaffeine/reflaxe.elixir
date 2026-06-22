package phoenix_hx_todo_hx.live;

import StringTools;
import elixir.types.Term;
import phoenix.LiveSocket;
import phoenix.Phoenix.EventParams;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountParams;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Session;
import phoenix.Phoenix.Socket;
import phoenix_hx_todo_hx.live.AppLiveTypes.AppLiveAssigns;

@:native("PhoenixHxTodoWeb.AppLive")
@:liveview
class AppLive {
	public static function mount(_params:MountParams, _session:Session, socket:Socket<AppLiveAssigns>):MountResult<AppLiveAssigns> {
		var owner = "Guest Workspace";
		var todos = TodoState.seed(owner);
		return Ok(socket.assign({
			authenticated: false,
			current_user_name: owner,
			current_user_email: "guest@example.test",
			title_input: "",
			notes_input: "",
			todos: todos,
			next_todo_id: 4,
			status: "Sign in or continue as guest to open the PhoenixHx board.",
			stats: TodoState.stats(todos)
		}));
	}

	public static function handleEvent(event:String, params:EventParams, socket:Socket<AppLiveAssigns>):HandleEventResult<AppLiveAssigns> {
		var live:LiveSocket<AppLiveAssigns> = socket;

		return switch (event) {
			case "continue_guest":
				NoReply(live.merge({
					authenticated: true,
					status: "Phoenix session demo active. The RailsHx Devise flow maps to Phoenix session/on_mount in production."
				}));
			case "logout":
				NoReply(live.merge({
					authenticated: false,
					status: "Signed out of the demo workspace."
				}));
			case "update_form":
				NoReply(live.merge({
					title_input: stringParam(params, "title"),
					notes_input: stringParam(params, "notes")
				}));
			case "create_todo":
				createTodo(params, live);
			case "toggle_todo":
				var id = intParam(params, "id");
				var todos = TodoState.toggle(live.assigns.todos, id);
				NoReply(live.merge({todos: todos, stats: TodoState.stats(todos), status: "Updated with a LiveView event, not a Turbo Stream."}));
			case "delete_todo":
				var id = intParam(params, "id");
				var todos = TodoState.deleteById(live.assigns.todos, id);
				NoReply(live.merge({todos: todos, stats: TodoState.stats(todos), status: "Deleted from LiveView state. Ecto persistence is the next slice."}));
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
							a LiveView event opens a demo workspace while the docs explain the production session/on_mount mapping.
						</p>
						<if ${assigns.status != null}>
							<div class="status" role="status">${assigns.status}</div>
						</if>
						<button type="button" class="primary-action" phx-click="continue_guest" data-testid="continue-guest" data-phoenixhx-autofocus>
							Continue as guest
						</button>
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
							<button type="button" class="secondary-action" phx-click="logout">Log out</button>
						</div>
					</header>

					<section class="hero">
						<div class="panel hero-copy">
							<span class="eyebrow">RailsHx sample, Phoenix implementation</span>
							<h1>Typed Phoenix, live BEAM state.</h1>
							<p>
								The RailsHx source renders ERB and Turbo Streams from Haxe. This port renders HEEx
								from inline HXX and handles mutations through LiveView events.
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
							<div><strong>ActionController action</strong><span>LiveView mount/event/render callbacks</span></div>
							<div><strong>HHX ERB partial</strong><span>Inline HXX function/component shape</span></div>
							<div><strong>Turbo Stream mutation</strong><span>LiveView event diff and PubSub-ready state</span></div>
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

		var nextId = socket.assigns.next_todo_id;
		var todos = TodoState.create(socket.assigns.todos, nextId, title, notes, socket.assigns.current_user_name);
		return NoReply(socket.merge({
			todos: todos,
			next_todo_id: nextId + 1,
			title_input: "",
			notes_input: "",
			stats: TodoState.stats(todos),
			status: "Task added through Phoenix LiveView."
		}));
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
