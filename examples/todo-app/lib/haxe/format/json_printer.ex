defmodule JsonPrinter do
  def new(replacer, space) do
    %{:replacer => replacer, :space => space}
  end
  defp write_value(struct, v, key) do
    v = if (struct.replacer != nil), do: struct.replacer(key, v), else: v
    if (v == nil), do: "null"
    if (Std.is(v, Bool)) do
      if v, do: "true", else: "false"
    end
    if (Std.is(v, Int)) do
      Std.string(v)
    end
    if (Std.is(v, Float)) do
      s = Std.string(v)
      if (s == "NaN" || s == "Infinity" || s == "-Infinity"), do: "null"
      s
    end
    if (Std.is(v, String)), do: struct.quote_string(v)
    if (Std.is(v, Array)), do: struct.write_array(v)
    struct.write_object(v)
  end
  defp write_array(struct, arr) do
    items = []
    g = 0
    g1 = length(arr)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    items ++ [struct.write_value(arr[i], Std.string(i))]
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
  end
end)
    if (struct.space != nil && length(items) > 0) do
      "[\n  " <> Enum.join(items, ",\n  ") <> "\n]"
    else
      "[" <> Enum.join(items, ",") <> "]"
    end
  end
  defp write_object(struct, obj) do
    fields = Map.keys(obj)
    pairs = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fields, g, :ok}, fn _, {acc_fields, acc_g, acc_state} ->
  if (acc_g < length(acc_fields)) do
    field = fields[g]
    acc_g = acc_g + 1
    value = Map.get(obj, field)
    key = struct.quote_string(field)
    val = struct.write_value(value, field)
    if (struct.space != nil), do: pairs ++ [key <> ": " <> val], else: pairs ++ [key <> ":" <> val]
    {:cont, {acc_fields, acc_g, acc_state}}
  else
    {:halt, {acc_fields, acc_g, acc_state}}
  end
end)
    if (struct.space != nil && length(pairs) > 0) do
      "{\n  " <> Enum.join(pairs, ",\n  ") <> "\n}"
    else
      "{" <> Enum.join(pairs, ",") <> "}"
    end
  end
  defp quote_string(_struct, s) do
    result = "\""
    g = 0
    g1 = length(s)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, result, :ok}, fn _, {acc_g, acc_g1, acc_result, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = s.char_code_at(i)
    if (c == nil), do: nil, else: nil
    {:cont, {acc_g, acc_g1, acc_result, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_result, acc_state}}
  end
end)
    result = result <> "\""
    result
  end
  def write(struct, k, v) do
    struct.write_value(v, k)
  end
  def print(o, replacer, space) do
    printer = JsonPrinter.new(replacer, space)
    printer.write_value(o, "")
  end
end