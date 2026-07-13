defmodule ElixirFirstLiveviewWeb.SearchLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {ElixirFirstLiveviewWeb.Layouts, :app}

  def mount(_params, _session, socket) do
    catalog = [
      "Phoenix LiveView",
      "Ecto Changesets",
      "Pattern Matching",
      "GenServer",
      "Supervision Trees",
      "PubSub",
      "Presence",
      "Telemetry"
    ]

    initial_assigns = %{
      query: "",
      catalog: catalog,
      visible: catalog,
      result_count: length(catalog),
      validation_error: nil
    }

    {:ok, Phoenix.Component.assign(socket, initial_assigns)}
  end

  defp apply_search(socket, query) do
    case ElixirFirstLiveview.SearchDomain.apply(query, socket.assigns.catalog) do
      {:ok, state} ->
        Phoenix.Component.assign(socket, %{
          query: state.query,
          visible: state.visible,
          result_count: state.result_count,
          validation_error: nil
        })

      {:error, reason} ->
        Phoenix.Component.assign(socket, %{
          query: socket.assigns.query,
          visible: socket.assigns.visible,
          result_count: socket.assigns.result_count,
          validation_error: reason
        })
    end
  end

  def render(assigns) do
    ~H"""
    <main class="mx-auto max-w-3xl p-6">
      <section class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <header class="mb-4">
          <p class="text-xs uppercase tracking-[0.14em] text-slate-500">Elixir-first typed mode</p>
          <h1 class="text-2xl font-semibold text-slate-900">Live search with typed boundaries</h1>
          <p class="mt-1 text-sm text-slate-600">
            Uses Phoenix/Elixir extern surfaces and Result-based domain flow from Haxe.
          </p>
        </header>

        <form phx-change="search" class="mb-3">
          <input
            type="text"
            name="query"
            value={@query}
            placeholder="Search BEAM topics..."
            class="w-full rounded-lg border border-slate-300 px-3 py-2"
          />
        </form>

        <p class="mb-3 text-sm text-slate-600" data-testid="result-count">
          {@result_count} result(s)
        </p>

        <%= if @validation_error != nil do %>
          <p class="mb-3 rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
            {@validation_error}
          </p>
        <% end %>

        <ul class="space-y-2" data-testid="search-results">
          <%= for entry <- @visible do %>
            <li class="rounded-md border border-slate-200 px-3 py-2 text-slate-800">{entry}</li>
          <% end %>
        </ul>
      </section>
    </main>
    """
  end

  def handle_event(event, params, socket) do
    if event != "search" do
      {:noreply, socket}
    else
      raw_query = Map.get(params, "query")

      query =
        if Reflaxe.Elixir.HaxeFloat.neq(raw_query, nil) and Kernel.is_binary(raw_query),
          do: raw_query,
          else: ""

      {:noreply, apply_search(socket, query)}
    end
  end
end
