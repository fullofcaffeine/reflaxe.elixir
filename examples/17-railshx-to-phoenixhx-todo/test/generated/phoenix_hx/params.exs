defmodule PhoenixHx.Params do
  def get(params, key) do
    if (Kernel.is_nil(params)) do
      nil
    else
      map = params
      string_key = key
      if (Map.has_key?(map, string_key)) do
        Map.get(params, string_key)
      else
        atom_key = existing_atom_or_null(key)
        if (not Kernel.is_nil(atom_key) and Map.has_key?(map, atom_key)) do
          Map.get(params, atom_key)
        else
          nil
        end
      end
    end
  end
  def get_string_default(params, key, default_value) do
    string_from_term_default(get(params, key), default_value)
  end
  def string_from_term(value) do
    if (not Kernel.is_nil(value)) do
      Kernel.to_string(value)
    else
      nil
    end
  end
  def string_from_term_default(value, default_value) do
    decoded = string_from_term(value)
    if (not Kernel.is_nil(decoded)), do: decoded, else: default_value
  end
  def get_int(params, key) do
    int_from_term(get(params, key))
  end
  def get_int_default(params, key, default_value) do
    value = get_int(params, key)
    if (not Kernel.is_nil(value)), do: value, else: default_value
  end
  def int_from_term(value) do
    if (Kernel.is_nil(value)) do
      nil
    else
      if (Kernel.is_integer(value)) do
        value
      else
        if (Kernel.is_float(value)) do
          trunc(value)
        else
          if (Kernel.is_binary(value)) do
            (case Integer.parse(value) do
              {num, _} -> num
              :error -> nil
            end)
          else
            nil
          end
        end
      end
    end
  end
  defp existing_atom_or_null(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> nil
    end
  end
end
