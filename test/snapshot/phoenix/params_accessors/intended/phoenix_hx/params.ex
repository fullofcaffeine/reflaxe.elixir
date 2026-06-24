defmodule PhoenixHx.Params do
  def get(params, key) do

              case params do
                nil -> nil
                params ->
                  case Map.fetch(params, key) do
                    {:ok, value} -> value
                    :error ->
                      try do
                        Map.get(params, String.to_existing_atom(key))
                      rescue
                        ArgumentError -> nil
                      end
                  end
              end

  end
  def get_nested(params, key, nested_key) do
    nested = get(params, key)
    if (Reflaxe.Elixir.HaxeFloat.neq(nested, nil)), do: get(nested, nested_key), else: nil
  end
  def get_string(params, key) do

              case PhoenixHx.Params.get(params, key) do
                nil -> nil
                value -> Kernel.to_string(value)
              end

  end
  def get_string_default(params, key, default_value) do
    value = get_string(params, key)
    if (not Kernel.is_nil(value)), do: value, else: default_value
  end
  def get_int(params, key) do
    int_from_term(get(params, key))
  end
  def get_nested_int(params, key, nested_key) do
    int_from_term(get_nested(params, key, nested_key))
  end
  def get_bool(params, key) do

              case PhoenixHx.Params.get(params, key) do
                value when is_boolean(value) -> value
                value when is_binary(value) ->
                  case String.downcase(String.trim(value)) do
                    "true" -> true
                    "1" -> true
                    "yes" -> true
                    "on" -> true
                    "false" -> false
                    "0" -> false
                    "no" -> false
                    "off" -> false
                    _ -> nil
                  end
                _ -> nil
              end

  end
  def get_int_default(params, key, default_value) do
    value = get_int(params, key)
    if (not Kernel.is_nil(value)), do: value, else: default_value
  end
  def get_nested_int_default(params, key, nested_key, default_value) do
    value = get_nested_int(params, key, nested_key)
    if (not Kernel.is_nil(value)), do: value, else: default_value
  end
  defp int_from_term(value) do

              case value do
                nil -> nil
                value when is_integer(value) -> value
                value when is_float(value) -> Kernel.trunc(value)
                value when is_binary(value) ->
                  case Integer.parse(value) do
                    {num, _} -> num
                    :error -> nil
                  end
                _ -> nil
              end

  end
end
