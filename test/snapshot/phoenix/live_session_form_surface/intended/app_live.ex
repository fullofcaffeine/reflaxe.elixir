defmodule AppLive do
  use Phoenix.Component
  use Phoenix.LiveView, layout: {AppLive.Layouts, :app}
  def mount(params, session, socket) do
    user = %{:id => 1, :name => "Ada"}
    params = %{:name => user.name}
    changeset = Ecto.Changeset.change(user, params)
    socket = Phoenix.Component.assign(socket, (fn -> %{:form => Phoenix.Component.to_form(changeset, (fn ->
  errors = nil
  action = nil
  method = nil
  multipart = nil

          [
            as: if(Kernel.is_nil("user"), do: nil, else: String.to_atom("user")),
            id: "user-form",
            errors: errors,
            action: if(Kernel.is_nil(action), do: nil, else: String.to_atom(action)),
            method: method,
            multipart: multipart
          ]
          |> Enum.filter(fn {_, value} -> value != nil end)

end).()), :search_form => Phoenix.Component.to_form(%{:query => ""}, (fn ->
  id = nil
  errors = nil
  action = nil
  method = nil
  multipart = nil

          [
            as: if(Kernel.is_nil("search"), do: nil, else: String.to_atom("search")),
            id: id,
            errors: errors,
            action: if(Kernel.is_nil(action), do: nil, else: String.to_atom(action)),
            method: method,
            multipart: multipart
          ]
          |> Enum.filter(fn {_, value} -> value != nil end)

end).()), :user_id =>
          case Map.get(session, "user_id") do
            value when is_integer(value) -> value
            _ -> nil
          end
} end).())
    {:ok, socket}
  end
  def handle_event(_event, params, socket) do
    {:noreply, Phoenix.Component.assign(socket, :search_form, (fn -> Phoenix.Component.to_form(params, (fn ->
  id = nil
  errors = nil
  action = nil
  method = nil
  multipart = nil

          [
            as: if(Kernel.is_nil("search"), do: nil, else: String.to_atom("search")),
            id: id,
            errors: errors,
            action: if(Kernel.is_nil(action), do: nil, else: String.to_atom(action)),
            method: method,
            multipart: multipart
          ]
          |> Enum.filter(fn {_, value} -> value != nil end)

end).()) end).())}
  end
end
