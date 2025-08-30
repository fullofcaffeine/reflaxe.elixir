defmodule TranslationBindings_Impl_ do
  defp _new(map) do
    fn map -> this_1 = nil
this_1 = map
this_1 end
  end
  def create() do
    fn -> map = %{}
this_1 = nil
this_1 = map
this_1 end
  end
  def set(this1, key, value) do
    fn this_1, key, value -> Map.put(this_1, key, value)
this_1 end
  end
  def setInt(this1, key, value) do
    fn this_1, key, value -> value = Std.string(value)
Map.put(this_1, key, value)
this_1 end
  end
  def setFloat(this1, key, value) do
    fn this_1, key, value -> value = Std.string(value)
Map.put(this_1, key, value)
this_1 end
  end
  def setBool(this1, key, value) do
    fn this_1, key, value -> Map.put(this_1, key, if (value) do
  "true"
else
  "false"
end)
this_1 end
  end
  def toMap(this1) do
    fn this_1 -> this_1 end
  end
end