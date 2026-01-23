defmodule JsonPrinter do
  import Kernel, except: [to_string: 1], warn: false
  def new() do
    struct = %{:buffer => nil}
    struct = %{struct | buffer: %StringBuf{}}
    struct
  end
  def write_array(struct, arr) do
    _ = StringBuf.add(struct.buffer, "[")
    items = ""
    _g = 0
    arr_length = length(arr)
    items = Enum.reduce(0..(arr_length - 1)//1, items, fn i, items_acc ->
      items_acc = if (i > 0), do: items_acc <> ", ", else: items_acc
      items_acc <> write_value(struct, Enum.at(arr, i))
    end)
    _ = StringBuf.add(struct.buffer, items)
    _ = StringBuf.add(struct.buffer, "]")
  end
  def write_object(struct, obj) do
    _ = StringBuf.add(struct.buffer, "{")
    fields = Reflect.fields(obj)
    result = ""
    _g = 0
    fields_length = length(fields)
    result = Enum.reduce(0..(fields_length - 1)//1, result, fn i, result_acc ->
      result_acc = if (i > 0), do: result_acc <> ", ", else: result_acc
      field = Enum.at(fields, i)
      value = (case {obj, field} do
        {reflect_obj, reflect_field} ->
          (case Map.fetch(reflect_obj, reflect_field) do
            {:ok, reflect_value} -> reflect_value
            _ ->
              (case (try do
  String.to_existing_atom(reflect_field)
rescue
  _ ->
    nil
end) do
                nil -> nil
                reflect_atom ->
                  Map.get(reflect_obj, reflect_atom)
              end)
          end)
      end)
      result_acc <> "\"" <> field <> "\": " <> write_value(struct, value)
    end)
    _ = StringBuf.add(struct.buffer, result)
    _ = StringBuf.add(struct.buffer, "}")
  end
  defp write_value(struct, v) do
    if (Kernel.is_nil(v)) do
      "null"
    else
      if (Std.is(v, Bool)) do
        inspect(v)
      else
        if (Std.is(v, Float) or Std.is(v, Int)) do
          inspect(v)
        else
          if (Std.is(v, String)) do
            "\"#{StringTools.replace(v, "\"", "\"")}\""
          else
            if (Std.is(v, Array)) do
              arr = v
              items = []
              _g = 0
              items = Enum.reduce(arr, items, fn item, items_acc -> Enum.concat(items_acc, [write_value(struct, item)]) end)
              "[#{Enum.join(items, ", ")}]"
            else
              "{}"
            end
          end
        end
      end
    end
  end
  def to_string(struct) do
    StringBuf.to_string(struct.buffer)
  end
end
