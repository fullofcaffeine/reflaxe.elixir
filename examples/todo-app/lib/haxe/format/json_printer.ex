defmodule JsonPrinter do
  def new(replacer, space) do
    %{:replacer => replacer, :space => space}
  end
  defp write_value(struct, v, key) do
    v = if (struct.replacer != nil), do: struct.replacer(key, v), else: v
    if (v == nil), do: "null"
    g = {:Typeof, v}
    case (g.elem(0)) do
      0 ->
        "null"
      1 ->
        Std.string(v)
      2 ->
        s = Std.string(v)
        if (s == "NaN" || s == "Infinity" || s == "-Infinity"), do: "null"
        s
      3 ->
        if v, do: "true", else: "false"
      4 ->
        struct.writeObject(v)
      5 ->
        "null"
      6 ->
        g = g.elem(1)
        c = g
        class_name = Type.get_class_name(c)
        if (class_name == "String") do
          struct.quoteString(v)
        else
          if (class_name == "Array"), do: struct.writeArray(v), else: struct.writeObject(v)
        end
      7 ->
        g = g.elem(1)
        "null"
      8 ->
        "null"
    end
  end
  defp write_array(struct, arr) do
    items = []
    g = 0
    g1 = arr.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, :ok}, fn _, {g, acc_state} ->
  if (g < g1) do
    i = g = g + 1
    items.push(struct.writeValue(arr[i], Std.string(i)))
    {:cont, {g, acc_state}}
  else
    {:halt, {g, acc_state}}
  end
end)
    if (struct.space != nil && items.length > 0) do
      "[\n  " <> Enum.join(items, ",\n  ") <> "\n]"
    else
      "[" <> Enum.join(items, ",") <> "]"
    end
  end
  defp write_object(struct, obj) do
    fields = Reflect.fields(obj)
    pairs = []
    g = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, :ok}, fn _, {g, acc_state} ->
  if (g < fields.length) do
    field = fields[g]
    g = g + 1
    value = Reflect.field(obj, field)
    key = struct.quoteString(field)
    val = struct.writeValue(value, field)
    if (struct.space != nil), do: pairs.push(key <> ": " <> val), else: pairs.push(key <> ":" <> val)
    {:cont, {g, acc_state}}
  else
    {:halt, {g, acc_state}}
  end
end)
    if (struct.space != nil && pairs.length > 0) do
      "{\n  " <> Enum.join(pairs, ",\n  ") <> "\n}"
    else
      "{" <> Enum.join(pairs, ",") <> "}"
    end
  end
  defp quote_string(struct, s) do
    result = "\""
    g = 0
    g1 = s.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, result, :ok}, fn _, {g, result, acc_state} ->
  if (g < g1) do
    i = g = g + 1
    c = s.charCodeAt(i)
    if (c == nil) do
      if (c < 32) do
        hex = StringTools.hex(c, 4)
        result = result <> "\\u" <> hex
      else
        result = result <> s.charAt(i)
      end
    else
      case (c) do
        8 ->
          result = result <> "\\b"
        9 ->
          result = result <> "\\t"
        10 ->
          result = result <> "\\n"
        12 ->
          result = result <> "\\f"
        13 ->
          result = result <> "\\r"
        34 ->
          result = result <> "\\\""
        92 ->
          result = result <> "\\\\"
        _ ->
          if (c < 32) do
            hex = StringTools.hex(c, 4)
            result = result <> "\\u" <> hex
          else
            result = result <> s.charAt(i)
          end
      end
    end
    {:cont, {g, result, acc_state}}
  else
    {:halt, {g, result, acc_state}}
  end
end)
    result = result <> "\""
    result
  end
  def write(struct, k, v) do
    struct.writeValue(v, k)
  end
  def print(o, _replacer, _space) do
    printer = JsonPrinter.new(replacer, space)
    printer.writeValue(o, "")
  end
end