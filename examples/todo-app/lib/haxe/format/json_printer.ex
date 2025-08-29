defmodule JsonPrinter do
  @moduledoc """
    JsonPrinter struct generated from Haxe

     * JsonPrinter: Simplified implementation avoiding mutable patterns
     *
     * WHY: The Haxe standard library JsonPrinter uses mutable StringBuf patterns
     * that don't translate well to Elixir's immutable world. This implementation
     * avoids those patterns by building strings functionally.
     *
     * WHAT: Functional implementation of JsonPrinter that generates valid Elixir
     *
     * HOW: Uses recursive string building without mutable state
  """

  defstruct [:replacer, :space]

  @type t() :: %__MODULE__{
    replacer: Null.t() | nil,
    space: Null.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(Null.t(), Null.t()) :: t()
  def new(arg0, arg1) do
    %__MODULE__{
      replacer: arg0,
      space: arg1
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Static functions
  @doc "Generated from Haxe print"
  def print(o, replacer \\ nil, space \\ nil) do
    printer = JsonPrinter.new(replacer, space)

    printer.write_value(o, "")
  end

  # Instance functions
  @doc "Generated from Haxe writeValue"
  def write_value(%__MODULE__{} = struct, v, key) do
    temp_result = nil

    if ((struct.replacer != nil)), do: v = struct.replacer(key, v), else: nil

    if ((v == nil)) do
      "null"
    else
      nil
    end

    g_array = Type.typeof(v)
    case g_array do
      0 -> "null"
      1 -> Std.string(v)
      2 -> s = Std.string(v)
    if ((((s == "NaN") || (s == "Infinity")) || (s == "-Infinity"))) do
      "null"
    else
      nil
    end
    s
      3 -> 
    if v, do: temp_result = "true", else: temp_result = "false"
    temp_result
      4 -> struct.write_object(v)
      5 -> "null"
      6 -> c = elem(g_array, 1)
    class_name = Type.get_class_name(c)
    if ((class_name == "String")) do
      struct.quote_string(v)
    else
      if ((class_name == "Array")) do
        struct.write_array(v)
      else
        struct.write_object(v)
      end
    end
      7 -> g_param_0 = elem(g_array, 1)
    "null"
      8 -> "null"
    end
  end

  @doc "Generated from Haxe writeArray"
  def write_array(%__MODULE__{} = struct, arr) do
    items = []

    g_counter = 0

    g_array = arr.length

    (fn loop ->
      if ((g_counter < g_array)) do
            i = g_counter + 1
        items = items ++ [struct.write_value(Enum.at(arr, i), Std.string(i))]
        loop.()
      end
    end).()

    if (((struct.space != nil) && (items.length > 0))) do
      "[\n  " <> Enum.join(items, ",\n  ") <> "\n]"
    else
      "[" <> Enum.join(items, ",") <> "]"
    end
  end

  @doc "Generated from Haxe writeObject"
  def write_object(%__MODULE__{} = struct, obj) do
    fields = Reflect.fields(obj)

    pairs = []

    g_counter = 0

    (fn loop ->
      if ((g_counter < fields.length)) do
            field = Enum.at(fields, g_counter)
        g_counter + 1
        _value = Reflect.field(obj, field)
        key = struct.quote_string(field)
        val = struct.write_value(_value, field)
        pairs = if ((struct.space != nil)), do: pairs ++ [key <> ": " <> val], else: pairs ++ [key <> ":" <> val]
        loop.()
      end
    end).()

    if (((struct.space != nil) && (pairs.length > 0))) do
      "{\n  " <> Enum.join(pairs, ",\n  ") <> "\n}"
    else
      "{" <> Enum.join(pairs, ",") <> "}"
    end
  end

  @doc "Generated from Haxe quoteString"
  def quote_string(%__MODULE__{} = struct, s) do
    result = "\""

    g_counter = 0

    g_array = s.length

    (fn loop ->
      if ((g_counter < g_array)) do
            i = g_counter + 1
        c = s.char_code_at(i)
        if ((c == nil)) do
          if ((c < 32)) do
            hex = StringTools.hex(c, 4)
            result = result <> "\\u" <> hex
          else
            result = result <> s.char_at(i)
          end
        else
          case c do
            8 -> result = result <> "\\b"
            9 -> result = result <> "\\t"
            10 -> result = result <> "\\n"
            12 -> result = result <> "\\f"
            13 -> result = result <> "\\r"
            34 -> result = result <> "\\\""
            92 -> result = result <> "\\\\"
            _ -> if ((c < 32)) do
            hex = StringTools.hex(c, 4)
            result = result <> "\\u" <> hex
          else
            result = result <> s.char_at(i)
          end
          end
        end
        loop.()
      end
    end).()

    result = result <> "\""

    result
  end

  @doc "Generated from Haxe write"
  def write(%__MODULE__{} = struct, k, v) do
    struct.write_value(v, k)
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
