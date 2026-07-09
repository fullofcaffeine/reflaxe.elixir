defmodule JsonPrinter do
  def new(replacer_param, space_param) do
    struct = %{:__reflaxe_class__ => JsonPrinter, :replacer => nil, :space => nil}
    struct = %{struct | replacer: replacer_param}
    struct = %{struct | space: space_param}
    struct
  end
  defp write_value(struct, v, key) do
    active_replacer = struct.replacer
    v = if (Reflaxe.Elixir.HaxeFloat.neq(active_replacer, nil)), do: active_replacer.(key, v), else: v
    cond do
      Reflaxe.Elixir.HaxeFloat.eq(v, nil) -> "null"
      Std.is(v, Bool) ->
        if (v), do: "true", else: "false"
      Std.is(v, Int) -> Reflaxe.Elixir.HaxeFloat.to_string(v)
      Std.is(v, Float) ->
        if (not Reflaxe.Elixir.HaxeFloat.is_finite(v)) do
          "null"
        else
          Reflaxe.Elixir.HaxeFloat.to_string(v)
        end
      Std.is(v, String) -> quote_string(struct, v)
      Std.is(v, Array) -> write_array(struct, v)
      true -> write_object(struct, v)
    end
  end
  defp write_array(struct, arr) do
    items = []
    _g = 0
    arr_length = length(arr)
    items = Enum.reduce(0..(arr_length - 1)//1, items, fn i, items_acc -> Enum.concat(items_acc, [write_value(struct, Enum.at(arr, i), Reflaxe.Elixir.HaxeFloat.to_string(i))]) end)
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
  defp quote_string(_struct, s) do
    result = "\""
    _g = 0
    s_length = String.length(s)
    result = Enum.reduce(0..(s_length - 1)//1, result, fn i, result_acc ->
      c = StringTools.haxe_char_code_at(s, i)
      if (Kernel.is_nil(c)) do
        if (c < 32) do
          hex = StringTools.hex(c, 4)
          result_acc <> "\\u" <> hex
        else
          result_acc <> StringTools.haxe_char_at(s, i)
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
              result_acc <> StringTools.haxe_char_at(s, i)
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
