package phoenix_chat_hx.live;

import StringTools;
import elixir.ElixirMap;
import elixir.Kernel;
import elixir.types.Term;
import phoenix.LiveSocket;
import phoenix.Params;
import phoenix.Phoenix.EventParams;
import phoenix.Phoenix.HandleEventResult;
import phoenix.Phoenix.MountParams;
import phoenix.Phoenix.MountResult;
import phoenix.Phoenix.Session;
import phoenix.Phoenix.Socket;
import phoenix_chat_hx.frontend.PreferenceDensity;
import phoenix_chat_hx.frontend.PreferenceStudioContract;
import phoenix_chat_hx.live.CremaInviteLiveTypes.CremaInviteAssigns;

/**
	Haxe-authored LiveView for the project-local Crema invitation proof.

	The page validates one in-memory request and renders native feedback. It does
	not persist, send, publish, or claim that an invitation effect happened.
	The trusted React island owns only draft density interaction; this LiveView
	retains the selected value, submit state, and a useful native fallback.
**/
@:native("PhoenixChatWeb.CremaInviteLive")
@:liveview
class CremaInviteLive {
	public static function mount(_params:MountParams, _session:Session, socket:Socket<CremaInviteAssigns>):MountResult<CremaInviteAssigns> {
		return Ok(socket.assign({
			page_title: "Morrow Field Office",
			name: "",
			email: "",
			project: "",
			request_state: "idle",
			request_status: null,
			preference_density: PreferenceDensity.Focused,
			preference_status: null,
		}));
	}

	public static function handleEvent(event:String, params:EventParams, socket:Socket<CremaInviteAssigns>):HandleEventResult<CremaInviteAssigns> {
		var live:LiveSocket<CremaInviteAssigns> = socket;
		return if (event == "submit_invite") {
			handleInviteSubmission(params, live);
		} else if (event == PreferenceStudioContract.EventName) {
			applyPreferenceDensity(PreferenceStudioContract.decodePayload(params), live);
		} else if (event == PreferenceStudioContract.NativeEventName) {
			applyPreferenceDensity(PreferenceStudioContract.decodeNativeButtonPayload(params), live);
		} else {
			NoReply(live);
		};
	}

	public static function render(assigns:CremaInviteAssigns):String {
		return <div class="crema-shell" data-state=${assigns.request_state} data-density=${assigns.preference_density}>
			<a class="crema-skip" href="#crema-request">Skip to invitation request</a>
			<div class="crema-grain" aria-hidden="true"></div>

			<header class="crema-masthead" aria-label="Morrow Field Office">
				<a class="crema-wordmark" href="/crema" aria-label="Morrow Field Office home">
					<span class="crema-wordmark__mark" aria-hidden="true">M</span>
					<span>
						<strong>Morrow</strong>
						<small>Field Office</small>
					</span>
				</a>
				<div class="crema-edition">
					<span>Private working circle</span>
					<strong>No. 07 / 2026</strong>
				</div>
				<a class="crema-masthead__action" href="#crema-request">Request a seat <span aria-hidden="true">↘</span></a>
			</header>

			<main>
				<section class="crema-hero" aria-labelledby="crema-title">
					<div class="crema-hero__index" aria-hidden="true">
						<span>01</span>
						<i></i>
						<span>Field note</span>
					</div>
					<div class="crema-hero__copy">
						<p class="crema-kicker">For people building work worth remembering</p>
						<h1 id="crema-title">Build in <em>company.</em><br />Think in peace.</h1>
						<p class="crema-deck">Morrow is a small, deliberate room for founders, makers, and researchers who want sharper conversation without another noisy feed.</p>
						<div class="crema-hero__notes" aria-label="Morrow qualities">
							<span>12 seats each season</span>
							<span>Long-form by default</span>
							<span>No engagement theater</span>
						</div>
					</div>

					<div class="crema-orbit" aria-hidden="true">
						<div class="crema-orbit__ring crema-orbit__ring--outer"></div>
						<div class="crema-orbit__ring crema-orbit__ring--inner"></div>
						<span class="crema-orbit__node crema-orbit__node--one"></span>
						<span class="crema-orbit__node crema-orbit__node--two"></span>
						<span class="crema-orbit__node crema-orbit__node--three"></span>
						<div class="crema-orbit__seal">
							<strong>12</strong>
							<span>open chairs</span>
						</div>
					</div>
				</section>

				<section class="crema-manifesto" aria-label="How Morrow works">
					<p><span>We keep the room small</span> so a half-formed thought can become a useful one before it becomes content.</p>
					<ol>
						<li><strong>01</strong><span>Bring one consequential question.</span></li>
						<li><strong>02</strong><span>Choose a working rhythm.</span></li>
						<li><strong>03</strong><span>Leave with a clearer next move.</span></li>
					</ol>
				</section>

				<section id="crema-request" class="crema-request" aria-labelledby="crema-request-title">
					<div class="crema-request__intro">
						<p class="crema-kicker">Invitation ledger / Autumn</p>
						<h2 id="crema-request-title">Tell us what you are trying to make true.</h2>
						<p>We read every note. This proving surface validates your request locally; it deliberately performs no external submission or storage effect.</p>
						<div class="crema-request__folio" aria-hidden="true">M / 07</div>
					</div>

					<div class="crema-request__form-column">
						<form class="crema-form" phx-submit="submit_invite" data-testid="crema-invite-form" novalidate>
							<div class="crema-field">
								<label for="crema-name"><span>01</span> Your name</label>
								<input id="crema-name" name="name" type="text" value=${assigns.name} autocomplete="name" minlength="2" maxlength="60" required aria-invalid=${assigns.request_state == "error"} placeholder="Ada Lovelace" />
							</div>
							<div class="crema-field">
								<label for="crema-email"><span>02</span> Correspondence</label>
								<input id="crema-email" name="email" type="email" value=${assigns.email} autocomplete="email" maxlength="120" required aria-invalid=${assigns.request_state == "error"} placeholder="ada@example.com" />
							</div>
							<div class="crema-field crema-field--wide">
								<label for="crema-project"><span>03</span> The question on your desk</label>
								<textarea id="crema-project" name="project" rows="4" minlength="12" maxlength="480" required aria-invalid=${assigns.request_state == "error"} placeholder="What are you building, changing, or trying to understand?">${assigns.project}</textarea>
							</div>
							<div class="crema-form__footer">
								<p>In-memory proof only. No provider call, email, or durable submission.</p>
								<button type="submit">
									<span class="crema-submit__idle">Prepare my request <i aria-hidden="true">→</i></span>
									<span class="crema-submit__pending" aria-hidden="true">Preparing request…</span>
								</button>
							</div>
						</form>

						<if ${assigns.request_status != null}>
							<div class=${"crema-form-status crema-form-status--" + assigns.request_state} role=${assigns.request_state == "error" ? "alert" : "status"} aria-live="polite" data-testid="crema-request-status">
								<span aria-hidden="true">${assigns.request_state == "error" ? "!" : "✓"}</span>
								<p>${assigns.request_status}</p>
							</div>
						</if>
					</div>

					<aside class="crema-rhythm" aria-labelledby="crema-rhythm-title">
						<div class="crema-rhythm__header">
							<div>
								<p class="crema-kicker">Interactive field card</p>
								<h2 id="crema-rhythm-title">Choose the room's working density.</h2>
							</div>
							<span>React / trusted</span>
						</div>

						<PhoenixChatWeb.ReactComponents.preference_studio
							id="crema-preference-studio"
							title="Working density"
							density=${assigns.preference_density}
						/>

						<details class="preference-fallback crema-rhythm__fallback" data-testid="crema-preference-fallback">
							<summary>Use native LiveView controls</summary>
							<p>The same semantic choice remains usable when the React island is removed.</p>
							<div class="preference-fallback__actions">
								<button type="button" phx-click=${PreferenceStudioContract.NativeEventName} phx-value-density="calm" aria-label="Use Calm native mode" aria-pressed=${assigns.preference_density == PreferenceDensity.Calm}>Calm</button>
								<button type="button" phx-click=${PreferenceStudioContract.NativeEventName} phx-value-density="focused" aria-label="Use Focused native mode" aria-pressed=${assigns.preference_density == PreferenceDensity.Focused}>Focused</button>
								<button type="button" phx-click=${PreferenceStudioContract.NativeEventName} phx-value-density="dense" aria-label="Use Dense native mode" aria-pressed=${assigns.preference_density == PreferenceDensity.Dense}>Dense</button>
							</div>
						</details>

						<if ${assigns.preference_status != null}>
							<div class="preference-status" role="status" data-testid="crema-preference-status">${assigns.preference_status}</div>
						</if>
					</aside>
				</section>
			</main>

			<footer class="crema-footer">
				<p><strong>Morrow Field Office</strong> / A project-local Crema proving surface.</p>
				<a href="/">Return to Phoenix Chat</a>
			</footer>
		</div>;
	}

	static function handleInviteSubmission(params:Term, socket:LiveSocket<CremaInviteAssigns>):HandleEventResult<CremaInviteAssigns> {
		var name = clean(Params.getString(params, "name"));
		var email = clean(Params.getString(params, "email"));
		var project = clean(Params.getString(params, "project"));
		var exactShape = Kernel.isMap(params) && ElixirMap.keys(params).length == 3;
		var valid = exactShape && name.length >= 2 && name.length <= 60 && email.length <= 120 && emailLooksValid(email) && project.length >= 12
			&& project.length <= 480;

		return if (!valid) {
			NoReply(socket.merge({
				name: name,
				email: email,
				project: project,
				request_state: "error",
				request_status: "Add a name, a valid email, and at least twelve characters about the question on your desk."
			}));
		} else {
			NoReply(socket.merge({
				name: name,
				email: email,
				project: project,
				request_state: "success",
				request_status: "Your request is ready for review. This proof intentionally stopped before storage, email, or any external effect."
			}));
		};
	}

	static function applyPreferenceDensity(decoded:Null<PreferenceDensity>, socket:LiveSocket<CremaInviteAssigns>):HandleEventResult<CremaInviteAssigns> {
		if (decoded == null) {
			return NoReply(socket.assign(_.preference_status, "Working-density payload rejected."));
		}
		var density:PreferenceDensity = decoded;
		return NoReply(socket.merge({
			preference_density: density,
			preference_status: 'Working density set to ${density.label()}.'
		}));
	}

	static function clean(value:Null<String>):String {
		return value == null ? "" : StringTools.trim(value);
	}

	static function emailLooksValid(value:String):Bool {
		var at = value.indexOf("@");
		var dot = value.lastIndexOf(".");
		return at > 0 && dot > at + 1 && dot < value.length - 1;
	}
}
