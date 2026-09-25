defmodule Reflect do
  def field(o, field) do
    if Map.has_key?(o, field) do
      Map.get(o, field)
    else
      try do
        Map.get(o, String.to_existing_atom(field))
      rescue
        ArgumentError -> nil
      end
    end
  end
end
