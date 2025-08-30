defmodule TranslationBindings_Impl_ do
  defp _new(map) do
    this_1 = nil
    this_1 = map
    this_1
  end
  def create() do
    map = %{}
    this_1 = nil
    this_1 = map
    this_1
  end
  def set(this1, key, value) do
    Map.put(this1, key, value)
    this1
  end
  def setInt(this1, key, value) do
    value = Std.string(value)
    Map.put(this1, key, value)
    this1
  end
  def setFloat(this1, key, value) do
    value = Std.string(value)
    Map.put(this1, key, value)
    this1
  end
  def setBool(this1, key, value) do
    Map.put(this1, key, if (value), do: "true", else: "false")
    this1
  end
  def toMap(this1) do
    this1
  end
end