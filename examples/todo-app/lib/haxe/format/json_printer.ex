defmodule JsonPrinter do
  def new(replacer, space) do
    %{:replacer => replacer, :space => space}
  end
  defp writeValue(struct, v, key) do
    if (struct.replacer != nil) do
      v = struct.replacer(key, v)
    end
    if (v == nil), do: "null"
    g = {:unknown, v}
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
  defp writeArray(struct, arr) do
    items = []
    g = 0
    g1 = arr.length
    (fn ->
      loop_9 = fn loop_9 ->
        if (g < g1) do
          i = g + 1
      items.push(struct.writeValue(arr[i], Std.string(i)))
          loop_9.(loop_9)
        else
          :ok
        end
      end
      loop_9.(loop_9)
    end).()
    if (struct.space != nil && items.length > 0), do: "[\n  " + items.join(",\n  ") + "\n]", else: "[" + items.join(",") + "]"
  end
  defp writeObject(struct, obj) do
    fields = Reflect.fields(obj)
    pairs = []
    g = 0
    (fn ->
      loop_10 = fn loop_10 ->
        if (g < fields.length) do
          field = fields[g]
      g + 1
      value = Reflect.field(obj, field)
      key = struct.quoteString(field)
      val = struct.writeValue(value, field)
      if (struct.space != nil), do: pairs.push(key + ": " + val), else: pairs.push(key + ":" + val)
          loop_10.(loop_10)
        else
          :ok
        end
      end
      loop_10.(loop_10)
    end).()
    if (struct.space != nil && pairs.length > 0), do: "{\n  " + pairs.join(",\n  ") + "\n}", else: "{" + pairs.join(",") + "}"
  end
  defp quoteString(struct, s) do
    result = "\""
    g = 0
    g1 = s.length
    (fn ->
      loop_11 = fn loop_11 ->
        if (g < g1) do
          i = g + 1
      c = s.charCodeAt(i)
      if (c == nil) do
        if (c < 32) do
          hex = StringTools.hex(c, 4)
          result = result + "\\u" + hex
        else
          result = result + s.charAt(i)
        end
      else
        case (c) do
          8 ->
            result = result + "\\b"
          9 ->
            result = result + "\\t"
          10 ->
            result = result + "\\n"
          12 ->
            result = result + "\\f"
          13 ->
            result = result + "\\r"
          34 ->
            result = result + "\\\""
          92 ->
            result = result + "\\\\"
          _ ->
            if (c < 32) do
              hex = StringTools.hex(c, 4)
              result = result + "\\u" + hex
            else
              result = result + s.charAt(i)
            end
        end
      end
          loop_11.(loop_11)
        else
          :ok
        end
      end
      loop_11.(loop_11)
    end).()
    result = result + "\""
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