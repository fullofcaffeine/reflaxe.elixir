defmodule HandwrittenCorpus.ElixirFirstLiveViewWeb.SearchLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    catalog = ["Phoenix LiveView", "Ecto Changesets", "Pattern Matching"]

    {:ok,
     assign(socket, query: "", catalog: catalog, visible: catalog, result_count: length(catalog))}
  end

  def handle_event("search", %{"query" => query}, socket) when is_binary(query) do
    {:noreply, apply_search(socket, query)}
  end

  def handle_event("search", _params, socket), do: {:noreply, apply_search(socket, "")}
  def handle_event(_event, _params, socket), do: {:noreply, socket}

  def render(assigns) do
    ~H"""
    <form phx-change="search">
      <input type="text" name="query" value={@query} />
    </form>
    <p>{@result_count} result(s)</p>
    """
  end

  defp apply_search(socket, query) do
    case HandwrittenCorpus.ElixirFirstLiveView.SearchDomain.apply(query, socket.assigns.catalog) do
      {:ok, state} -> assign(socket, Map.put(state, :validation_error, nil))
      {:error, reason} -> assign(socket, :validation_error, reason)
    end
  end
end
