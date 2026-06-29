defmodule TodoFormEvents do
  def encode(event) do
    (case event do
      {:create_todo, payload} ->
        form_payload = %{}
        wire_payload = %{}
        form_payload = form_payload |> Map.put("done", payload.done) |> Map.put("estimate", payload.estimate) |> Map.put("notes", payload.notes) |> Map.put("priority", payload.priority) |> Map.put("title", payload.title)
        wire_payload = Map.put(wire_payload, "todo", form_payload)
        %{:event => "create_todo", :payload => wire_payload}
      {:update_form, payload} ->
        form_payload = %{}
        wire_payload = %{}
        form_payload = form_payload |> Map.put("done", payload.done) |> Map.put("estimate", payload.estimate) |> Map.put("notes", payload.notes) |> Map.put("priority", payload.priority) |> Map.put("title", payload.title)
        wire_payload = Map.put(wire_payload, "todo", form_payload)
        %{:event => "update_form", :payload => wire_payload}
      {:clear_completed} ->
        form_payload = %{}
        wire_payload = %{}
        wire_payload = Map.put(wire_payload, "todo", form_payload)
        %{:event => "clear_completed", :payload => wire_payload}
    end)
  end
  def decode(event_name, payload) do
    if (event_name == "clear_completed") do
      {:clear_completed}
    else
      if (event_name == "create_todo") do
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
          :true -> nil
        end
        estimate_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "estimate")
        else
          nil
        end
        estimate = cond do
          Kernel.is_float(estimate_raw) or Kernel.is_integer(estimate_raw) -> estimate_raw
          Kernel.is_binary(estimate_raw) -> Reflaxe.Elixir.HaxeFloat.parse(estimate_raw)
          :true -> nil
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
          :true -> nil
        end
        title_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
          Map.get(event_payload, "title")
        else
          nil
        end
        title = if (Kernel.is_binary(title_raw)), do: title_raw, else: nil
        if (not Kernel.is_nil(done) and not Kernel.is_nil(estimate) and not Kernel.is_nil(priority) and not Kernel.is_nil(title)), do: {:create_todo, %{:done => done, :estimate => estimate, :notes => notes, :priority => priority, :title => title}}, else: nil
      else
        if (event_name == "update_form") do
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
            :true -> nil
          end
          estimate_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
            Map.get(event_payload, "estimate")
          else
            nil
          end
          estimate = cond do
            Kernel.is_float(estimate_raw) or Kernel.is_integer(estimate_raw) -> estimate_raw
            Kernel.is_binary(estimate_raw) -> Reflaxe.Elixir.HaxeFloat.parse(estimate_raw)
            :true -> nil
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
            :true -> nil
          end
          title_raw = if (not Kernel.is_nil(event_payload) and Kernel.is_map(event_payload)) do
            Map.get(event_payload, "title")
          else
            nil
          end
          title = if (Kernel.is_binary(title_raw)), do: title_raw, else: nil
          if (not Kernel.is_nil(done) and not Kernel.is_nil(estimate) and not Kernel.is_nil(priority) and not Kernel.is_nil(title)), do: {:update_form, %{:done => done, :estimate => estimate, :notes => notes, :priority => priority, :title => title}}, else: nil
        else
          nil
        end
      end
    end
  end
end
