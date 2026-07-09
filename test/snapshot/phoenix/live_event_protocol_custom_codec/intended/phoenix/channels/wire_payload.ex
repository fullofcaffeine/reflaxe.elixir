defmodule Phoenix.Channels.WirePayload do
  def empty() do
    %{}
  end
  def put_payload(payload, key, value) do
    Map.put(payload, key, value)
  end
  def put_string(payload, key, value) do
    Map.put(payload, key, value)
  end
  def put_int(payload, key, value) do
    Map.put(payload, key, value)
  end
  def put_bool(payload, key, value) do
    Map.put(payload, key, value)
  end
  def put_float(payload, key, value) do
    Map.put(payload, key, value)
  end
  def put_string_array(payload, key, value) do
    Map.put(payload, key, value)
  end
  def put_int_array(payload, key, value) do
    Map.put(payload, key, value)
  end
  def get(payload, key) do
    if (Reflaxe.Elixir.HaxeFloat.eq(payload, nil) or Kernel.is_nil(key)) do
      nil
    else
      value = Map.get(payload, key)
      if (Reflaxe.Elixir.HaxeFloat.neq(value, nil)) do
        value
      else
        atom = try do
          :erlang.binary_to_existing_atom(key)
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {haxe_catch_value, _} when is_struct(haxe_catch_value, Reflaxe.Exception) or is_map(haxe_catch_value) and is_map_key(haxe_catch_value, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, haxe_catch_value) == Reflaxe.Exception -> nil
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
        if (Reflaxe.Elixir.HaxeFloat.neq(atom, nil)) do
          Map.get(payload, atom)
        else
          nil
        end
      end
    end
  end
  def get_string(payload, key) do
    value = get(payload, key)
    if (Reflaxe.Elixir.HaxeFloat.eq(value, nil)) do
      nil
    else
      if (Kernel.is_binary(value)) do
        value
      else
        if (Kernel.is_atom(value)) do
          :erlang.atom_to_binary(value)
        else
          if (Kernel.is_integer(value) or Kernel.is_float(value) or Kernel.is_boolean(value)) do
            Kernel.to_string(value)
          else
            nil
          end
        end
      end
    end
  end
  def get_int(payload, key) do
    value = get(payload, key)
    if (Reflaxe.Elixir.HaxeFloat.eq(value, nil)) do
      nil
    else
      if (Kernel.is_integer(value)) do
        value
      else
        if (Kernel.is_float(value)) do
          if value == trunc(value), do: trunc(value), else: nil
        else
          if (Kernel.is_binary(value)) do
            case Integer.parse(value) do {n, ""} -> n; _ -> nil end
          else
            nil
          end
        end
      end
    end
  end
  def get_bool(payload, key) do
    value = get(payload, key)
    if (Reflaxe.Elixir.HaxeFloat.eq(value, nil)) do
      nil
    else
      if (Kernel.is_boolean(value)), do: value, else: nil
    end
  end
  def get_float(payload, key) do
    value = get(payload, key)
    if (Reflaxe.Elixir.HaxeFloat.eq(value, nil)) do
      nil
    else
      if (Kernel.is_float(value)) do
        value
      else
        if (Kernel.is_integer(value)) do
          value * 1.0
        else
          nil
        end
      end
    end
  end
  def get_payload(payload, key) do
    value = get(payload, key)
    if (Reflaxe.Elixir.HaxeFloat.eq(value, nil)) do
      nil
    else
      if (Kernel.is_map(value)), do: value, else: nil
    end
  end
  def get_string_array(payload, key) do
    value = get(payload, key)
    if (Reflaxe.Elixir.HaxeFloat.eq(value, nil) or not Kernel.is_list(value)) do
      nil
    else
      items = value
      ok = Enum.all?(items, fn item -> Kernel.is_binary(item) or Kernel.is_atom(item) end)
      if (not ok) do
        nil
      else
        Enum.map(items, fn item ->
          if (Kernel.is_atom(item)) do
            :erlang.atom_to_binary(item)
          else
            item
          end
        end)
      end
    end
  end
  def get_int_array(payload, key) do
    value = get(payload, key)
    if (Reflaxe.Elixir.HaxeFloat.eq(value, nil) or not Kernel.is_list(value)) do
      nil
    else

                  Enum.reduce_while(value, [], fn v, acc ->
                    cond do
                      is_integer(v) ->
                        {:cont, [v | acc]}

                      is_float(v) and v == trunc(v) ->
                        {:cont, [trunc(v) | acc]}

                      is_binary(v) ->
                        case Integer.parse(v) do
                          {n, ""} -> {:cont, [n | acc]}
                          _ -> {:halt, :error}
                        end

                      true ->
                        {:halt, :error}
                    end
                  end)
                  |> case do
                    :error -> nil
                    acc -> Enum.reverse(acc)
                  end

    end
  end
end
