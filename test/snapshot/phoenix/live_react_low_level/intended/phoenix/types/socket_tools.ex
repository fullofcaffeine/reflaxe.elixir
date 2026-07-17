defmodule SocketTools do
  def has_assign(socket, key) do
    assigns = Assigns_Impl_.to_dynamic(Socket_Impl_.get_assigns(socket))
    (case {assigns, key} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> true
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> false
              reflect_atom ->
                Map.has_key?(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_assign_or(socket, key, default_value) do
    assigns = Assigns_Impl_.to_dynamic(Socket_Impl_.get_assigns(socket))
    if ((case {assigns, key} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> true
          false ->
            (case (try do
              String.to_existing_atom(reflect_field)
            rescue
              _ ->
                nil
            end) do
              nil -> false
              reflect_atom ->
                Map.has_key?(reflect_obj, reflect_atom)
            end)
        end)
    end)) do
      (case {assigns, key} do
        {reflect_obj, reflect_field} ->
          (case Map.fetch(reflect_obj, reflect_field) do
            {:ok, reflect_value} -> reflect_value
            _ ->
              (case (try do
                String.to_existing_atom(reflect_field)
              rescue
                _ ->
                  nil
              end) do
                nil -> nil
                reflect_atom ->
                  Map.get(reflect_obj, reflect_atom)
              end)
          end)
      end)
    else
      default_value
    end
  end
  def is_in_state(socket, state_name, state_value) do
    Reflaxe.Elixir.HaxeFloat.eq(Socket_Impl_.get_assign(socket, state_name), state_value)
  end
  def get_current_user(socket) do
    Socket_Impl_.get_assign(socket, "current_user")
  end
  def get_flash(socket) do
    Socket_Impl_.get_assign(socket, "flash")
  end
  def has_flash(socket) do
    flash = get_flash(socket)
    Reflaxe.Elixir.HaxeFloat.neq(flash, nil) and length(Reflect.fields(flash)) > 0
  end
end
