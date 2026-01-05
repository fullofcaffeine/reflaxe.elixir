defmodule JsonPrinter do
  def new(replacer_param, space_param) do
    struct = %{:replacer => nil, :space => nil}
    struct = %{struct | replacer: replacer_param}
    struct = %{struct | space: space_param}
    struct
  end
  defp write_value(struct, v, key) do
    v = if (not Kernel.is_nil(struct.replacer)) do
      replacer(struct, key, v)
    else
      v
    end
    if (Kernel.is_nil(v)) do
      "null"
    else
      if (Std.is(v, Bool)) do
        if (v), do: "true", else: "false"
      else
        if (Std.is(v, Int)) do
          inspect(v)
        else
          if (Std.is(v, Float)) do
            s = inspect(v)
            if (s == "NaN" or s == "Infinity" or s == "-Infinity"), do: "null", else: s
            if (Std.is(v, String)) do
              quote_string(struct, v)
            else
              if (Std.is(v, Array)), do: write_array(struct, v), else: write_object(struct, v)
            end
          else
            if (Std.is(v, String)) do
              quote_string(struct, v)
            else
              if (Std.is(v, Array)), do: write_array(struct, v), else: write_object(struct, v)
            end
          end
        end
      end
    end
  end
  defp write_array(struct, arr) do
    items = []
    _g = 0
    arr_length = length(arr)
    items = Enum.reduce(0..(arr_length - 1)//1, items, fn i, items_acc -> Enum.concat(items_acc, [write_value(struct, arr[i], inspect(i))]) end)
    if (not Kernel.is_nil(struct.space) and length(items) > 0) do
      "[
  #{Enum.join(items, ",\n  ")}
]"
    else
      "[#{Enum.join(items, ",")}]"
    end
  end
  defp write_object(struct, obj) do
    fields = Reflect.fields(obj)
    pairs = []
    _g = 0
    pairs = Enum.reduce(fields, pairs, fn field, pairs_acc ->
      value = Map.get(obj, field)
      key = quote_string(struct, field)
      val = write_value(struct, value, field)
      if (not Kernel.is_nil(struct.space)) do
        Enum.concat(pairs_acc, [key <> ": " <> val])
      else
        Enum.concat(pairs_acc, [key <> ":" <> val])
      end
    end)
    if (not Kernel.is_nil(struct.space) and length(pairs) > 0) do
      "{
  #{Enum.join(pairs, ",\n  ")}
}"
    else
      "{#{Enum.join(pairs, ",")}}"
    end
  end
  defp quote_string(_, s) do
    result = "\""
    _g = 0
    s_length = String.length(s)
    result = Enum.reduce(0..(s_length - 1)//1, result, fn i, result_acc ->
      c = if (i < 0) do
        nil
      else
        Enum.at(String.to_charlist(s), i)
      end
      if (Kernel.is_nil(c)) do
        if (c < 32) do
          hex = StringTools.hex(c, 4)
          result_acc <> "\\u" <> hex
        else
          result_acc <> (if (i < 0) do
  ""
else
  String.at(s, i) || ""
end)
        end
      else
        (case c do
          8 ->
            result_acc = result_acc <> "\\b"
            result_acc
          9 ->
            result_acc = result_acc <> "\\t"
            result_acc
          10 ->
            result_acc = result_acc <> "\\n"
            result_acc
          12 ->
            result_acc = result_acc <> "\\f"
            result_acc
          13 ->
            result_acc = result_acc <> "\\r"
            result_acc
          34 ->
            result_acc = result_acc <> "\\\""
            result_acc
          92 ->
            result_acc = result_acc <> "\\\\"
            result_acc
          _ ->
            result_acc = if (c < 32) do
  hex = StringTools.hex(c, 4)
  result_acc <> "\\u" <> hex
else
  result_acc <> (if (i < 0) do
  ""
else
  String.at(s, i) || ""
end)
end
            result_acc
        end)
      end
    end)
    result = "#{result}\""
    result
  end
  def write(struct, k, v) do
    write_value(struct, v, k)
  end
  def print(o, replacer_param, space_param) do
    printer = JsonPrinter.new(replacer_param, space_param)
    _ = write_value(printer, o, "")
  end
end
