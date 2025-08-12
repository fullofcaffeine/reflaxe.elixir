defmodule ReflaxeElixirWeb.DashboardLive do
  use ReflaxeElixirWeb, :live_view
  
  alias ReflaxeElixir.Analytics
  alias ReflaxeElixir.Analytics.Metric
  
  
  
  @impl true
  def mount(params, session, socket) do
    
    
    {:ok,
     socket
     |> assign(:page_title, "DashboardLive")
      |> assign(:metrics, Analytics.list_metrics())
         |> assign(:selected_metric, nil)
         |> assign(:changeset, nil)
 |> assign(:show_modal, false) |> assign(:sort_by, "id")
         |> assign(:sort_order, :asc)
         |> assign(:filter_text, "")
         |> assign(:current_page, 1)
         |> assign(:per_page, 10)
}
  end
  
  @impl true
def handle_event("new_metric", _params, socket) do
  changeset = Analytics.change_metric(%Metric{})
  
  {:noreply,
   socket
   |> assign(:changeset, changeset)
   |> assign(:selected_metric, nil)
   |> assign(:show_modal, true)}
end

  @impl true
def handle_event("edit_metric", %{"id" => id}, socket) do
  metric = Analytics.get_metric!(id)
  changeset = Analytics.change_metric(metric)
  
  {:noreply,
   socket
   |> assign(:selected_metric, metric)
   |> assign(:changeset, changeset)
   |> assign(:show_modal, true)}
end

  @impl true
def handle_event("save", %{"metric" => metric_params}, socket) do
  save_metric(socket, socket.assigns.selected_metric, metric_params)
end

  @impl true
def handle_event("paginate", %{"page" => page}, socket) do
  {:noreply,
   socket
   |> assign(:current_page, String.to_integer(page))
   |> apply_filters()}
end

  @impl true
def handle_event("filter", %{"filter" => filter_text}, socket) do
  {:noreply,
   socket
   |> assign(:filter_text, filter_text)
   |> assign(:current_page, 1)
   |> apply_filters()}
end

  @impl true
def handle_event("sort", %{"field" => field}, socket) do
  sort_order = if socket.assigns.sort_by == field do
    toggle_sort_order(socket.assigns.sort_order)
  else
    :asc
  end
  
  {:noreply,
   socket
   |> assign(:sort_by, field)
   |> assign(:sort_order, sort_order)
   |> apply_filters()}
end

  @impl true
def handle_event("close_modal", _params, socket) do
  {:noreply,
   socket
   |> assign(:show_modal, false)
   |> assign(:changeset, nil)
   |> assign(:selected_item, nil)}
end

  
  
  
  @impl true
def render(assigns) do
  ~H"""
  <div class="metric">
    <.header>
      Metric Management
      <:actions>
        <.button phx-click="new_metric">
  <.icon name="hero-plus" /> New Metric
</.button>

      </:actions>
    </.header>
    
    <.table id="metrics" rows={@metrics}>
  <:col :let={metric} label="ID"><%= metric.id %></:col>
  <:col :let={metric} label="Name"><%= metric.name %></:col>
  <:action :let={metric}>
    <.link phx-click="edit_metric" phx-value-id={metric.id}>
      Edit
    </.link>
  </:action>
  <:action :let={metric}>
    <.link
      phx-click="delete_metric"
      phx-value-id={metric.id}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>

    
    <.modal :if={@show_modal} id="metric-modal" show on_cancel={JS.push("close_modal")}>
  <.header>
    <%= if @selected_metric, do: "Edit", else: "New" %> Metric
  </.header>
  
  <.simple_form
    for={@changeset}
    id="metric-form"
    phx-submit="save"
  >
    <.input field={@changeset[:name]} type="text" label="Name" />
    
    <:actions>
      <.button phx-disable-with="Saving...">Save Metric</.button>
    </:actions>
  </.simple_form>
</.modal>

  </div>
  """
end

  
  
  
  defp apply_filters(socket) do
  metrics = Analytics.list_metrics()
  
  # Apply text filter
  filtered = if socket.assigns.filter_text != "" do
    Enum.filter(metrics, fn metric ->
      String.contains?(
        String.downcase(metric.name || ""),
        String.downcase(socket.assigns.filter_text)
      )
    end)
  else
    metrics
  end
  
  # Apply sorting
  sorted = Enum.sort_by(filtered, & Map.get(&1, String.to_atom(socket.assigns.sort_by)), socket.assigns.sort_order)
  
  # Apply pagination
  start_index = (socket.assigns.current_page - 1) * socket.assigns.per_page
  paginated = Enum.slice(sorted, start_index, socket.assigns.per_page)
  
  assign(socket, :metrics, paginated)
end

  defp toggle_sort_order(:asc), do: :desc
defp toggle_sort_order(:desc), do: :asc

  defp save_metric(socket, nil, metric_params) do
  case Analytics.create_metric(metric_params) do
    {:ok, metric} ->
      
      
      {:noreply,
       socket
       |> assign(:metrics, Analytics.list_metrics())
       |> assign(:changeset, nil)
       |> assign(:selected_metric, nil)
       |> assign(:show_modal, false)
       |> put_flash(:info, "Metric created successfully")}
       
    {:error, changeset} ->
      {:noreply, assign(socket, :changeset, changeset)}
  end
end

defp save_metric(socket, metric, metric_params) do
  case Analytics.update_metric(metric, metric_params) do
    {:ok, metric} ->
      
      
      {:noreply,
       socket
       |> assign(:metrics, Analytics.list_metrics())
       |> assign(:changeset, nil)
       |> assign(:selected_metric, nil)
       |> assign(:show_modal, false)
       |> put_flash(:info, "Metric updated successfully")}
       
    {:error, changeset} ->
      {:noreply, assign(socket, :changeset, changeset)}
  end
end

end
