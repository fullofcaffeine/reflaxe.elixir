defmodule TranslationBindings_Impl_ do
  defp _new(map) do
    map
  end
  def create() do
    map = %{}
    temp_result = map
    tempResult
  end
  def set(this1, key, value) do
    this1 = Map.put(this1, key, value)
    this1
  end
  def set_int(this1, key, value) do
    value2 = Std.string(value)
    this1 = Map.put(this1, key, value2)
    this1
  end
  def set_float(this1, key, value) do
    value2 = Std.string(value)
    this1 = Map.put(this1, key, value2)
    this1
  end
  def set_bool(this1, key, value) do
    temp_string = nil
    if value do
      temp_string = "true"
    else
      temp_string = "false"
    end
    this1 = Map.put(this1, key, tempString)
    this1
  end
  def to_map(this1) do
    this1
  end
end