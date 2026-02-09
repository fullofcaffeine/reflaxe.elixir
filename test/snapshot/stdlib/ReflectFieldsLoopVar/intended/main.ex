defmodule Main do
  def main() do
    all_users = %{:user_123 => %{:metas => [%{:online_at => 1234567890, :user_name => "Alice", :editing_todo_id => 42}]}, :user_456 => %{:metas => [%{:online_at => 1234567891, :user_name => "Bob", :editing_todo_id => nil}]}}
    editing_users = []
    _g = 0
    g_value = Reflect.fields(all_users)
    _ = Enum.reduce(g_value, editing_users, fn user_id, editing_users_acc ->
      entry = (case {all_users, user_id} do
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
      if (length(entry.metas) > 0) do
        meta = Enum.at(entry.metas, 0)
        if (meta.editing_todo_id == 42) do
          Enum.concat(editing_users_acc, [meta])
        else
          editing_users_acc
        end
      else
        editing_users_acc
      end
    end)
    user_names = []
    _g = 0
    g_value = Reflect.fields(all_users)
    _ = Enum.reduce(g_value, user_names, fn user_id, user_names_acc ->
      entry = (case {all_users, user_id} do
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
      meta_list = entry.metas
      if (length(meta_list) > 0) do
        first_meta = user_id
        name = first_meta.user_name
        Enum.concat(user_names_acc, [name])
      else
        user_names_acc
      end
    end)
    all_metadata = []
    _g = 0
    g_value = Reflect.fields(all_users)
    _ = Enum.reduce(g_value, all_metadata, fn user_id, all_metadata_acc ->
      user_entry = (case {all_users, user_id} do
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
      _g = 0
      g_value = length(user_entry.metas)
      Enum.reduce(0..(g_value - 1)//1, all_metadata_acc, fn i, all_metadata_acc ->
        meta_item = Enum.at(user_entry.metas, i)
        processed_meta = %{:id => user_id, :index => i, :data => meta_item}
        Enum.concat(all_metadata_acc, [processed_meta])
      end)
    end)
    _g = 0
    g_value = Reflect.fields(all_users)
    _ = Enum.each(g_value, fn user_id ->
  _entry = (case {all_users, user_id} do
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
  nil
end)
    user_name_map = %{}
    _g = 0
    g_value = Reflect.fields(all_users)
    _ = Enum.each(g_value, fn user_id ->
  entry = (case {all_users, user_id} do
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
  if (length(entry.metas) > 0) do
    meta = Enum.at(entry.metas, 0)
    _ = (case {user_name_map, user_id, meta.user_name} do
      {reflect_obj, reflect_field, reflect_value} ->
        (case Map.has_key?(reflect_obj, reflect_field) do
          true ->
            Map.put(reflect_obj, reflect_field, reflect_value)
          false ->
            (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
              nil ->
                Map.put(reflect_obj, reflect_field, reflect_value)
              reflect_atom ->
                Map.put(reflect_obj, reflect_atom, reflect_value)
            end)
        end)
    end)
  end
end)
    nil
  end
end
