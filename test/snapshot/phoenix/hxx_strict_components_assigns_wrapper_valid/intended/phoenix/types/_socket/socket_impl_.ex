defmodule Socket_Impl_ do
  def from_dynamic(socket) do
    socket
  end
  def to_dynamic(this1) do
    this1
  end
  def get_assigns(this1) do
    Assigns_Impl_.from_dynamic(((case {this1, "assigns"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)))
  end
  def get_assign(this1, key) do
    assigns = (case {this1, "assigns"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    (case {assigns, key} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def is_connected(this1) do
    not Kernel.is_nil(((case {this1, "transport_pid"} do
  {reflect_obj, reflect_field} ->
    (case Map.fetch(reflect_obj, reflect_field) do
      {:ok, reflect_value} -> reflect_value
      _ ->
        (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
          nil -> nil
          reflect_atom ->
            Map.get(reflect_obj, reflect_atom)
        end)
    end)
end)))
  end
  def get_id(this1) do
    (case {this1, "id"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_transport(this1) do
    _transport = (case {this1, "transport"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
    {:web_socket}
  end
  def get_endpoint(this1) do
    (case {this1, "endpoint"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_router(this1) do
    (case {this1, "router"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_view(this1) do
    (case {this1, "view"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_changed(this1) do
    (case {this1, "changed"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def has_changed(this1, key) do
    changed = get_changed(this1)
    (case {changed, key} do
      {reflect_obj, reflect_field} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true -> true
          false ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> false
              reflect_atom ->
                Map.has_key?(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_parent_pid(this1) do
    (case {this1, "parent_pid"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_root_pid(this1) do
    (case {this1, "root_pid"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
  def get_transport_pid(this1) do
    (case {this1, "transport_pid"} do
      {reflect_obj, reflect_field} ->
        (case Map.fetch(reflect_obj, reflect_field) do
          {:ok, reflect_value} -> reflect_value
          _ ->
            (case try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end do
              nil -> nil
              reflect_atom ->
                Map.get(reflect_obj, reflect_atom)
            end)
        end)
    end)
  end
end
