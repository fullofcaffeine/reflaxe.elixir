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
  def get_string(params, key) do
    string_from_term(get(params, key))
  end
  def string_from_term(value) do
    if (not Kernel.is_nil(value)) do
      Kernel.to_string(value)
    else
      nil
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
