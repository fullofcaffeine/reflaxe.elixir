defmodule TranslationBindings_Impl_ do
  defp _new() do
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
  def set() do
    fn this_1, key, value -> Map.put(this_1, key, value)
this_1 end
  end
  def setInt() do
    fn this_1, key, value -> value = Std.string(value)
Map.put(this_1, key, value)
this_1 end
  end
  def setFloat() do
    fn this_1, key, value -> value = Std.string(value)
Map.put(this_1, key, value)
this_1 end
  end
  def setBool() do
    fn this_1, key, value -> Map.put(this_1, key, if (value) do
  "true"
else
  "false"
end)
this_1 end
  end
  def toMap() do
    fn this_1 -> this_1 end
  end
end