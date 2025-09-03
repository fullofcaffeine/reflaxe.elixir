defmodule TranslationBindings_Impl_ do
  defp _new(map) do
    this1 = map
    this1
  end
  def create() do
    map = %{}
    this1 = map
    this1
  end
  def set(this1, key, value) do
    this1 = Map.put(this1, key, value)
    this1
  end
  def set_int(this1, key, value) do
    value = Std.string(value)
    this1 = Map.put(this1, key, value)
    this1
  end
  def set_float(this1, key, value) do
    value = Std.string(value)
    this1 = Map.put(this1, key, value)
    this1
  end
  def set_bool(this1, key, value) do
    this1 = Map.put(this1, key, (if value, do: "true", else: "false"))
    this1
  end
  def to_map(this1) do
    this1
  end
end