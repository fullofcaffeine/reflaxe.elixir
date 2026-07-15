defmodule PhoenixChatWeb.CremaInviteLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {PhoenixChatWeb.Layouts, :app}
  def mount(_params, _session, socket) do
    {:ok, Phoenix.Component.assign(socket, %{page_title: "Morrow Field Office", name: "", email: "", project: "", request_state: "idle", request_status: nil, preference_density: "focused", preference_status: nil})}
  end
  def render(assigns) do
    ~H"""
    <div class="crema-shell" data-state={@request_state} data-density={@preference_density}>
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
                    <input id="crema-name" name="name" type="text" value={@name} autocomplete="name" minlength="2" maxlength="60" required aria-invalid={@request_state == "error"} placeholder="Ada Lovelace" />
                  </div>
                  <div class="crema-field">
                    <label for="crema-email"><span>02</span> Correspondence</label>
                    <input id="crema-email" name="email" type="email" value={@email} autocomplete="email" maxlength="120" required aria-invalid={@request_state == "error"} placeholder="ada@example.com" />
                  </div>
                  <div class="crema-field crema-field--wide">
                    <label for="crema-project"><span>03</span> The question on your desk</label>
                    <textarea id="crema-project" name="project" rows="4" minlength="12" maxlength="480" required aria-invalid={@request_state == "error"} placeholder="What are you building, changing, or trying to understand?"><%= @project %></textarea>
                  </div>
                  <div class="crema-form__footer">
                    <p>In-memory proof only. No provider call, email, or durable submission.</p>
                    <button type="submit">
                      <span class="crema-submit__idle">Prepare my request <i aria-hidden="true">→</i></span>
                      <span class="crema-submit__pending" aria-hidden="true">Preparing request…</span>
                    </button>
                  </div>
                </form>

                <%= if @request_status != nil do %>
                  <div class={"crema-form-status crema-form-status--" <> assigns.request_state} role={(if (assigns.request_state == "error"), do: "alert", else: "status")} aria-live="polite" data-testid="crema-request-status">
                    <span aria-hidden="true"><%= (if (assigns.request_state == "error"), do: "!", else: "✓") %></span>
                    <p><%= @request_status %></p>
                  </div>
                <% end %>
              </div>

              <aside class="crema-rhythm" aria-labelledby="crema-rhythm-title">
                <div class="crema-rhythm__header">
                  <div>
                    <p class="crema-kicker">Interactive field card</p>
                    <h2 id="crema-rhythm-title">Choose the room's working density.</h2>
                  </div>
                  <span>React / trusted</span>
                </div>

                <PhoenixChatWeb.ReactComponents.preference_studio id="crema-preference-studio" title="Working density" density={@preference_density}></PhoenixChatWeb.ReactComponents.preference_studio>

                <details class="preference-fallback crema-rhythm__fallback" data-testid="crema-preference-fallback">
                  <summary>Use native LiveView controls</summary>
                  <p>The same semantic choice remains usable when the React island is removed.</p>
                  <div class="preference-fallback__actions">
                    <button type="button" phx-click={"preference_changed_native"} phx-value-density="calm" aria-label="Use Calm native mode" aria-pressed={@preference_density == "calm"}>Calm</button>
                    <button type="button" phx-click={"preference_changed_native"} phx-value-density="focused" aria-label="Use Focused native mode" aria-pressed={@preference_density == "focused"}>Focused</button>
                    <button type="button" phx-click={"preference_changed_native"} phx-value-density="dense" aria-label="Use Dense native mode" aria-pressed={@preference_density == "dense"}>Dense</button>
                  </div>
                </details>

                <%= if @preference_status != nil do %>
                  <div class="preference-status" role="status" data-testid="crema-preference-status"><%= @preference_status %></div>
                <% end %>
              </aside>
            </section>
          </main>

          <footer class="crema-footer">
            <p><strong>Morrow Field Office</strong> / A project-local Crema proving surface.</p>
            <a href="/">Return to Phoenix Chat</a>
          </footer>
        </div>
    """
  end
  defp handle_invite_submission(params, socket) do
    name = clean(PhoenixHx.Params.get_string(params, "name"))
    email = clean(PhoenixHx.Params.get_string(params, "email"))
    project = clean(PhoenixHx.Params.get_string(params, "project"))
    exact_shape = Kernel.is_map(params) and length(Map.keys(params)) == 3
    valid = exact_shape and String.length(name) >= 2 and String.length(name) <= 60 and String.length(email) <= 120 and email_looks_valid(email) and String.length(project) >= 12 and String.length(project) <= 480
    if (not valid), do: {:noreply, Phoenix.Component.assign(socket, %{name: name, email: email, project: project, request_state: "error", request_status: "Add a name, a valid email, and at least twelve characters about the question on your desk."})}, else: {:noreply, Phoenix.Component.assign(socket, %{name: name, email: email, project: project, request_state: "success", request_status: "Your request is ready for review. This proof intentionally stopped before storage, email, or any external effect."})}
  end
  defp apply_preference_density(decoded, socket) do
    if (Kernel.is_nil(decoded)) do
      {:noreply, Phoenix.Component.assign(socket, :preference_status, "Working-density payload rejected.")}
    else
      density = decoded
      {:noreply, Phoenix.Component.assign(socket, %{preference_density: density, preference_status: "Working density set to " <> PhoenixChat.PreferenceDensity_Impl_.label(density) <> "."})}
    end
  end
  defp clean(value) do
    if (Kernel.is_nil(value)) do
      ""
    else
      StringTools.ltrim(StringTools.rtrim(value))
    end
  end
  defp email_looks_valid(value) do
    at = StringTools.haxe_index_of(value, "@", 0)
    dot = StringTools.haxe_last_index_of(value, ".", nil)
    at > 0 and dot > at + 1 and dot < (String.length(value) - 1)
  end
  def handle_event(event, params, socket) do
    live = socket
    cond do
      event == "submit_invite" -> handle_invite_submission(params, live)
      event == "preference_changed" -> apply_preference_density(PhoenixChat.PreferenceStudioContract.decode_payload(params), live)
      event == "preference_changed_native" -> apply_preference_density(PhoenixChat.PreferenceStudioContract.decode_native_button_payload(params), live)
      true -> {:noreply, live}
    end
  end
end
