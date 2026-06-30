defmodule MyAppWeb.FormLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {MyAppWeb.Layouts, :app}
  def render(assigns) do
    ~H"""
<form phx-submit={"create_todo"} phx-change={"update_form"}>
			<input type="text" name="todo[title]" value={@summary} />
		</form>
"""
  end
  def create_event_name() do
    "create_todo"
  end
  def decode_create(payload) do
    MyApp.TodoFormEvents.decode("create_todo", payload)
  end
  defp handle_create_todo(payload, socket) do
    {:noreply, Phoenix.Component.assign(socket, :summary, payload.title <> ":" <> Reflaxe.Elixir.HaxeFloat.to_string(payload.priority))}
  end
  defp handle_update_form(payload, socket) do
    {:noreply, Phoenix.Component.assign(socket, :summary, payload.title <> ":" <> Reflaxe.Elixir.HaxeFloat.to_string(payload.done))}
  end
  defp handle_clear_completed(socket) do
    {:noreply, Phoenix.Component.assign(socket, :summary, "cleared")}
  end
  defp dispatch_todo_form_event(event_name, payload, socket) do
    cond do
      event_name == "clear_completed" -> handle_clear_completed(socket)
      event_name == "create_todo" ->
        event_payload = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
          Map.get(payload, "todo")
        else
          nil
        end
        done_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "done")
        else
          nil
        end
        done = cond do
          Kernel.is_boolean(done_raw) -> done_raw
          Kernel.is_binary(done_raw) ->
            if (Kernel.to_string(done_raw) == "true") do
              true
            else
              if (Kernel.to_string(done_raw) == "false"), do: false, else: nil
            end
          true -> nil
        end
        estimate_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "estimate")
        else
          nil
        end
        estimate = cond do
          Kernel.is_float(estimate_raw) or Kernel.is_integer(estimate_raw) -> estimate_raw
          Kernel.is_binary(estimate_raw) -> Reflaxe.Elixir.HaxeFloat.parse(estimate_raw)
          true -> nil
        end
        notes_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "notes")
        else
          nil
        end
        notes = if (Kernel.is_binary(notes_raw)), do: notes_raw, else: nil
        priority_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "priority")
        else
          nil
        end
        priority = cond do
          Kernel.is_integer(priority_raw) -> priority_raw
          Kernel.is_binary(priority_raw) ->
            (case Integer.parse(priority_raw) do
              {num, _} -> num
              :error -> nil
            end)
          true -> nil
        end
        title_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "title")
        else
          nil
        end
        title = if (Kernel.is_binary(title_raw)), do: title_raw, else: nil
        if (Kernel.is_nil(done) or Kernel.is_nil(estimate) or Kernel.is_nil(priority) or Kernel.is_nil(title)), do: {:noreply, socket}, else: handle_create_todo(%{:done => done, :estimate => estimate, :notes => notes, :priority => priority, :title => title}, socket)
      event_name == "update_form" ->
        event_payload = if (not Kernel.is_nil(payload) and Kernel.is_map(payload)) do
          Map.get(payload, "todo")
        else
          nil
        end
        done_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "done")
        else
          nil
        end
        done = cond do
          Kernel.is_boolean(done_raw) -> done_raw
          Kernel.is_binary(done_raw) ->
            if (Kernel.to_string(done_raw) == "true") do
              true
            else
              if (Kernel.to_string(done_raw) == "false"), do: false, else: nil
            end
          true -> nil
        end
        estimate_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "estimate")
        else
          nil
        end
        estimate = cond do
          Kernel.is_float(estimate_raw) or Kernel.is_integer(estimate_raw) -> estimate_raw
          Kernel.is_binary(estimate_raw) -> Reflaxe.Elixir.HaxeFloat.parse(estimate_raw)
          true -> nil
        end
        notes_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "notes")
        else
          nil
        end
        notes = if (Kernel.is_binary(notes_raw)), do: notes_raw, else: nil
        priority_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "priority")
        else
          nil
        end
        priority = cond do
          Kernel.is_integer(priority_raw) -> priority_raw
          Kernel.is_binary(priority_raw) ->
            (case Integer.parse(priority_raw) do
              {num, _} -> num
              :error -> nil
            end)
          true -> nil
        end
        title_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "title")
        else
          nil
        end
        title = if (Kernel.is_binary(title_raw)), do: title_raw, else: nil
        if (Kernel.is_nil(done) or Kernel.is_nil(estimate) or Kernel.is_nil(priority) or Kernel.is_nil(title)), do: {:noreply, socket}, else: handle_update_form(%{:done => done, :estimate => estimate, :notes => notes, :priority => priority, :title => title}, socket)
      true -> nil
    end
  end
  def handle_event(event, params, socket) do
    handled = dispatch_todo_form_event(event, params, socket)
    if (not Kernel.is_nil(handled)), do: handled, else: {:noreply, socket}
  end
end
