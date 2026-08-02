defmodule PhoenixhxLiveReactWeb.SignalConsoleLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {PhoenixhxLiveReactWeb.Layouts, :app}
  def mount(_params, _session, socket) do
    {:ok, Phoenix.Component.assign(socket, %{pulse_count: 0, channel: "ALPHA", status: "Waiting for a signal."})}
  end
  defp handle_pulse(payload, socket) do
    channel = normalize_channel(payload.channel)
    count = socket.assigns.pulse_count + 1
    {:noreply, Phoenix.Component.assign(socket, %{pulse_count: count, channel: channel, status: "Server received " <> channel <> " pulse " <> String.pad_leading(Integer.to_string(count), 2, "0") <> "."})}
  end
  defp normalize_channel(candidate) do
    (case candidate do
      "ALPHA" -> candidate
      "BETA" -> candidate
      "GAMMA" -> candidate
      _ -> "ALPHA"
    end)
  end
  def render(assigns) do
    ~H"""
    <main class="integration-shell">
          <header class="integration-nav">
            <a href="/" class="integration-mark" aria-label="PhoenixHx LiveReact example home">PHX<span>×</span>HX</a>
            <p>Integration specimen 018</p>
            <a href="https://github.com/fullofcaffeine/reflaxe.elixir" rel="noreferrer">Source ↗</a>
          </header>

          <section class="integration-hero">
            <div class="integration-copy">
              <p class="integration-kicker">Haxe → Elixir · TypeScript · React</p>
              <h1>One typed server.<br /><em>A familiar browser.</em></h1>
              <p class="integration-lede">
                Phoenix renders the host and handles a typed event. Plain TypeScript owns the
                React island, showing that LiveReact does not require a Haxe browser compiler.
              </p>

              <ol class="integration-route" aria-label="Application compilation route">
                <li><span>01</span><b>Haxe server</b><small>Reflaxe.Elixir</small></li>
                <li><span>02</span><b>Phoenix host</b><small>BEAM runtime</small></li>
                <li><span>03</span><b>TypeScript</b><small>Vite</small></li>
                <li><span>04</span><b>React island</b><small>LiveReact</small></li>
              </ol>
            </div>

            <div class="integration-demo">
              <div class="integration-demo__label">
                <span>Interactive proof</span>
                <span>Client only / SSR off</span>
              </div>
              <PhoenixhxLiveReactWeb.ReactIslands.SignalConsole.render id="signal-console" title="Signal console" pulse_count={@pulse_count}></PhoenixhxLiveReactWeb.ReactIslands.SignalConsole.render>

              <p class="signal-console-server-status" role="status" data-testid="server-status"><%= @status %></p>
              <details class="signal-console-fallback" data-testid="native-fallback">
                <summary>Native LiveView fallback</summary>
                <p>This button sends the same typed event without React.</p>
                <button type="button" phx-click={"signal_pulse"} phx-value-channel={@channel} data-testid="native-transmit-pulse">Transmit <%= @channel %> pulse</button>
              </details>
            </div>
          </section>

          <footer class="integration-footer">
            <p><span aria-hidden="true">●</span> Static registry · closed props · stock LiveReact runtime</p>
            <p>Open the README for the exact local workflow and ownership map.</p>
          </footer>
        </main>
    """
  end
  defp dispatch_signal_console_event(event_name, payload, socket) do
    if event_name == "signal_pulse" do
      event_payload = if not Kernel.is_nil(payload) and Kernel.is_map(payload), do: payload, else: %{}
      channel_raw = Map.get(event_payload, "channel")
      channel = if (Kernel.is_binary(channel_raw)), do: channel_raw, else: nil
      if (Kernel.is_nil(channel)), do: {:noreply, socket}, else: handle_pulse(%{channel: channel}, socket)
    else
      nil
    end
  end
  def handle_event(event, params, socket) do
    typed_result = dispatch_signal_console_event(event, params, socket)
    if (not Kernel.is_nil(typed_result)), do: typed_result, else: {:noreply, socket}
  end
end
