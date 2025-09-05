defmodule JsonPrinter do
  def new(replacer, space) do
    %{:replacer => replacer, :space => space}
  end
  defp write_value(struct, v, key) do
    v = if (struct.replacer != nil), do: struct.replacer(key, v), else: v
    if (v == nil), do: "null"
    g = {:Typeof, v}
    case (elem(g, 0)) do
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
        g = elem(g, 1)
        c = g
        class_name = Type.get_class_name(c)
        if (class_name == "String") do
          struct.quoteString(v)
        else
          if (class_name == "Array"), do: struct.writeArray(v), else: struct.writeObject(v)
        end
      7 ->
        _g = elem(g, 1)
        "null"
      8 ->
        "null"
    end
  end
  defp write_array(struct, arr) do
    items = []
    g = 0
    g1 = arr.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g, :ok}, fn _, {acc_g1, acc_g, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    items ++ [struct.writeValue(arr[i], Std.string(i))]
    {:cont, {acc_g1, acc_g, acc_state}}
  else
    {:halt, {acc_g1, acc_g, acc_state}}
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {fields, g, :ok}, fn _, {acc_fields, acc_g, acc_state} ->
  if (acc_g < acc_fields.length) do
    field = fields[g]
    acc_g = acc_g + 1
    value = Reflect.field(obj, field)
    key = struct.quoteString(field)
    val = struct.writeValue(value, field)
    if (struct.space != nil), do: pairs ++ [key <> ": " <> val], else: pairs ++ [key <> ":" <> val]
    {:cont, {acc_fields, acc_g, acc_state}}
  else
    {:halt, {acc_fields, acc_g, acc_state}}
  end
end)
    if (struct.space != nil && pairs.length > 0) do
      "{\n  " <> Enum.join(pairs, ",\n  ") <> "\n}"
    else
      "{" <> Enum.join(pairs, ",") <> "}"
    end
  end
  defp quote_string(_struct, s) do
    result = "\""
    g = 0
    g1 = s.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, result, :ok}, fn _, {acc_g, acc_g1, acc_result, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    c = s.charCodeAt(i)
    if (c == nil) do
      if (c < 32) do
        hex = StringTools.hex(c, 4)
        acc_result = acc_result <> "\\u" <> hex
      else
        acc_result = acc_result <> s.charAt(i)
      end
    else
      case (c) do
        8 ->
          acc_result = acc_result <> "\\b"
        9 ->
          acc_result = acc_result <> "\\t"
        10 ->
          acc_result = acc_result <> "\\n"
        12 ->
          acc_result = acc_result <> "\\f"
        13 ->
          acc_result = acc_result <> "\\r"
        34 ->
          acc_result = acc_result <> "\\\""
        92 ->
          acc_result = acc_result <> "\\\\"
        _ ->
          if (c < 32) do
            hex = StringTools.hex(c, 4)
            acc_result = acc_result <> "\\u" <> hex
          else
            acc_result = acc_result <> s.charAt(i)
          end
      end
    end
    {:cont, {acc_g, acc_g1, acc_result, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_result, acc_state}}
  end
end)
    result = result <> "\""
    result
  end
  def write(struct, k, v) do
    struct.writeValue(v, k)
  end
  def print(o, replacer, space) do
    printer = JsonPrinter.new(replacer, space)
    printer.writeValue(o, "")
  end
end