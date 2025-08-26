defmodule JsonPrinter do
  @moduledoc """
    JsonPrinter struct generated from Haxe

      An implementation of JSON printer in Haxe.

      This class is used by `haxe.Json` when native JSON implementation
      is not available.

      @see https://haxe.org/manual/std-Json-encoding.html
  """

  defstruct [:buf, :replacer, :indent, :pretty, :nind]

  @type t() :: %__MODULE__{
    buf: StringBuf.t() | nil,
    replacer: Function.t() | nil,
    indent: String.t() | nil,
    pretty: boolean() | nil,
    nind: integer() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(Function.t(), String.t()) :: t()
  def new(arg0, arg1) do
    %__MODULE__{
      buf: arg0,
      replacer: arg1,
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Static functions
  @doc "Generated from Haxe print"
  def print(o, _replacer \\ nil, space \\ nil) do
    printer = Haxe.Format.JsonPrinter.new(replacer, space)

    printer.write("", o)

    printer.buf.b
  end

  # Instance functions
  @doc "Generated from Haxe write"
  def write(%__MODULE__{} = struct, k, v) do
    temp_string = nil

    if ((struct.replacer != nil)), do: v = struct.replacer(k, v), else: nil

    g_array = Type.typeof(v)
    case (case g_array do :t_null -> 0; :t_int -> 1; :t_float -> 2; :t_bool -> 3; :t_object -> 4; :t_function -> 5; :t_class -> 6; :t_enum -> 7; :t_unknown -> 8; _ -> -1 end) do
      0 -> struct = struct.buf
    struct.b = struct.b <> "null"
      1 -> struct = struct.buf
    struct.b = struct.b <> Std.string(v)
      2 -> 
    if Math.is_finite(v), do: temp_string = Std.string(v), else: temp_string = "null"
    v = temp_string
    struct = struct.buf
    struct.b = struct.b <> Std.string(v)
      3 -> struct = struct.buf
    struct.b = struct.b <> Std.string(v)
      4 -> struct.fields_string(v, Reflect.fields(v))
      5 -> struct = struct.buf
    struct.b = struct.b <> "\"<fun>\""
      {6, c} -> g_array = elem(g_array, 1)
    if ((c == String)) do
      struct.quote_(v)
    else
      if ((c == Array)) do
        v = v
        struct = struct.buf
        struct.b = struct.b <> "["
        len = v.length
        last = (len - 1)
        g_counter = 0
        g_array = len
        v
        |> Enum.with_index()
        |> Enum.each(fn {item, i} ->
          i = g_counter + 1
          if ((i > 0)) do
            struct = struct.buf
            struct.b = struct.b <> ","
          else
            struct.nind + 1
          end
          if struct.pretty do
            struct = struct.buf
            struct.b = struct.b <> "\n"
          else
            nil
          end
          if struct.pretty do
            v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
            struct = struct.buf
            struct.b = struct.b <> Std.string(v)
          else
            nil
          end
          struct.write(i, item)
          if ((i == last)) do
            struct.nind - 1
            if struct.pretty do
              struct = struct.buf
              struct.b = struct.b <> "\n"
            else
              nil
            end
            if struct.pretty do
              v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
              struct = struct.buf
              struct.b = struct.b <> Std.string(v)
            else
              nil
            end
          else
            nil
          end
        end)
        struct = struct.buf
        struct.b = struct.b <> "]"
      else
        if ((c == StringMap)) do
          v = v
          o = %{}
          k = v.keys()
          (
            # Simple module-level pattern (inline for now)
            loop_helper = fn condition_fn, body_fn, loop_fn ->
              if condition_fn.() do
                body_fn.()
                loop_fn.(condition_fn, body_fn, loop_fn)
              else
                nil
              end
            end
          
            loop_helper.(
              fn -> k.has_next() end,
              fn ->
                k = k.next()
                Reflect.set_field(o, k, v.get(k))
              end,
              loop_helper
            )
          )
          v = o
          struct.fields_string(v, Reflect.fields(v))
        else
          if ((c == Date)) do
            v = v
            struct.quote_(v.to_string())
          else
            struct.class_string(v)
          end
        end
      end
    end
      7 -> i = Type.enum_index(v)
    v = Std.string(i)
    struct = struct.buf
    struct.b = struct.b <> Std.string(v)
      8 -> struct = struct.buf
    struct.b = struct.b <> "\"???\""
    end
  end

  @doc "Generated from Haxe classString"
  def class_string(%__MODULE__{} = struct, v) do
    struct.fields_string(v, Type.get_instance_fields(Type.get_class(v)))
  end

  @doc "Generated from Haxe fieldsString"
  def fields_string(%__MODULE__{} = struct, v, fields) do
    struct = struct.buf
    struct.b = struct.b <> "{"

    len = fields.length

    empty = true

    g_counter = 0

    g_array = len

    fields
    |> Enum.with_index()
    |> Enum.each(fn {item, i} ->
      i = g_counter + 1
      f = item
      value = Reflect.field(v, f)
      if Reflect.is_function_(value) do
        throw(:continue)
      else
        nil
      end
      if empty do
        struct.nind + 1
        empty = false
      else
        struct = struct.buf
        struct.b = struct.b <> ","
      end
      if struct.pretty do
        struct = struct.buf
        struct.b = struct.b <> "\n"
      else
        nil
      end
      if struct.pretty do
        v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
        struct = struct.buf
        struct.b = struct.b <> Std.string(v)
      else
        nil
      end
      struct.quote_(f)
      struct = struct.buf
      struct.b = struct.b <> ":"
      if struct.pretty do
        struct = struct.buf
        struct.b = struct.b <> " "
      else
        nil
      end
      struct.write(f, value)
    end)

    if (not empty) do
      struct.nind - 1
      if struct.pretty do
        struct = struct.buf
        struct.b = struct.b <> "\n"
      else
        nil
      end
      if struct.pretty do
        v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
        struct = struct.buf
        struct.b = struct.b <> Std.string(v)
      else
        nil
      end
    else
      nil
    end

    struct = struct.buf
    struct.b = struct.b <> "}"
  end

  @doc "Generated from Haxe quote"
  def quote_(%__MODULE__{} = struct, s) do
    struct = struct.buf
    struct.b = struct.b <> "\""

    i = 0

    length = s.length

    for <<char <- s>> do
      char_code = char
      index = g_counter + 1
      case (char_code) do
        _ ->
          struct = struct.buf
      struct.b = struct.b <> "\\b"
        _ ->
          struct = struct.buf
      struct.b = struct.b <> "\\t"
        _ ->
          struct = struct.buf
      struct.b = struct.b <> "\\n"
        _ ->
          struct = struct.buf
      struct.b = struct.b <> "\\f"
        _ ->
          struct = struct.buf
      struct.b = struct.b <> "\\r"
        _ ->
          struct = struct.buf
      struct.b = struct.b <> "\\\""
        _ ->
          struct = struct.buf
      struct.b = struct.b <> "\\\\"
        _ -> struct = struct.buf
      struct.b = struct.b <> String.from_char_code(char_code)
      end
    end

    struct = struct.buf
    struct.b = struct.b <> "\""
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
