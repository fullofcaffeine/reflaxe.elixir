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
  @doc """
    Encodes `o`'s value and returns the resulting JSON string.

    If `replacer` is given and is not null, it is used to retrieve
    actual object to be encoded. The `replacer` function takes two parameters,
    the key and the value being encoded. Initial key value is an empty string.

    If `space` is given and is not null, the result will be pretty-printed.
    Successive levels will be indented by this string.
  """
  @spec print(term(), Null.t(), Null.t()) :: String.t()
  def print(o, replacer, space) do
    (
          printer = Haxe.Format.JsonPrinter.new(&JsonPrinter.replacer/2, space)
          printer.write("", o)
          printer.buf.b
        )
  end

  # Instance functions
  @doc "Function write"
  @spec write(t(), term(), term()) :: nil
  def write(%__MODULE__{} = struct, k, v) do
    (
          if ((struct.replacer != nil)) do
          v = struct.replacer(k, v)
        end
          (
          g = Type.typeof(v)
          case (elem(g, 0)) do
      0 -> _this = %{_this.buf | b: "null"}
      1 -> _this = %{_this.buf | b: Std.string(v)}
      2 -> (
          temp_string = nil
          if (Math.is_finite(v)) do
          temp_string = Std.string(v)
        else
          temp_string = "null"
        end
          v = temp_string
          _this = %{_this.buf | b: Std.string(v)}
        )
      3 -> _this = %{_this.buf | b: Std.string(v)}
      4 -> struct.fields_string(v, Reflect.fields(v))
      5 -> _this = %{_this.buf | b: "\"<fun>\""}
      6 -> (
          g = elem(g, 1)
          c = g
          if ((c == String)) do
          struct.quote_(v)
        else
          if ((c == Array)) do
          v = v
    _this = %{_this.buf | b: "["}
    len = v.length
    last = (len - 1)
    g_counter = 0
    g = len
    while_loop(fn -> ((g < g)) end, fn -> (
          i = g + 1
          if ((i > 0)) do
          _this = %{_this.buf | b: ","}
        else
          struct.nind + 1
        end
          if (struct.pretty) do
          _this = %{_this.buf | b: "\n"}
        end
          if (struct.pretty) do
          (
          v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
          _this = %{_this.buf | b: Std.string(v)}
        )
        end
          struct.write(i, Enum.at(v, i))
          if ((i == last)) do
          (
          struct.nind - 1
          if (struct.pretty) do
          _this = %{_this.buf | b: "\n"}
        end
          if (struct.pretty) do
          (
          v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
          _this = %{_this.buf | b: Std.string(v)}
        )
        end
        )
        end
        ) end)
    _this = %{_this.buf | b: "]"}
        else
          if ((c == StringMap)) do
          (
          v = v
          o = %{}
          k = v.keys()
          while_loop(fn -> (k.has_next()) end, fn -> (
          k = k.next()
          Reflect.set_field(o, k, v.get(k))
        ) end)
          (
          v = o
          struct.fields_string(v, Reflect.fields(v))
        )
        )
        else
          if ((c == Date)) do
          (
          v = v
          struct.quote_(v.to_string())
        )
        else
          struct.class_string(v)
        end
        end
        end
        end
        )
      7 -> (
          elem(g, 1)
          (
          i = Type.enum_index(v)
          (
          v = Std.string(i)
          _this = %{_this.buf | b: Std.string(v)}
        )
        )
        )
      8 -> _this = %{_this.buf | b: "\"???\""}
    end
        )
        )
  end

  @doc "Function class_string"
  @spec class_string(t(), term()) :: nil
  def class_string(%__MODULE__{} = struct, v) do
    struct.fields_string(v, Type.get_instance_fields(Type.get_class(v)))
  end

  @doc "Function fields_string"
  @spec fields_string(t(), term(), Array.t()) :: nil
  def fields_string(%__MODULE__{} = struct, v, fields) do
    _this = %{_this.buf | b: "{"}
    len = fields.length
    empty = true
    g_counter = 0
    g = len
    while_loop(fn -> ((g < g)) end, fn -> i = g + 1
    f = Enum.at(fields, i)
    value = Reflect.field(v, f)
    if (Reflect.is_function_(value)) do
          throw(:continue)
        end
    if (empty) do
          (
          struct.nind + 1
          empty = false
        )
        else
          _this = %{_this.buf | b: ","}
        end
    if (struct.pretty) do
          _this = %{_this.buf | b: "\n"}
        end
    if (struct.pretty) do
          (
          v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
          _this = %{_this.buf | b: Std.string(v)}
        )
        end
    struct.quote_(f)
    _this = %{_this.buf | b: ":"}
    if (struct.pretty) do
          _this = %{_this.buf | b: " "}
        end
    struct.write(f, value) end)
    if (not empty) do
          (
          struct.nind - 1
          if (struct.pretty) do
          _this = %{_this.buf | b: "\n"}
        end
          if (struct.pretty) do
          (
          v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
          _this = %{_this.buf | b: Std.string(v)}
        )
        end
        )
        end
    _this = %{_this.buf | b: "}"}
  end

  @doc "Function quote_"
  @spec quote_(t(), String.t()) :: nil
  def quote_(%__MODULE__{} = struct, s) do
    (
          _this = %{_this.buf | b: "\""}
          i = 0
          length = s.length
          while_loop(fn -> ((i < length)) end, fn -> (
          temp_number = nil
          index = i + 1
          temp_number = s.cca(index)
          c = temp_number
          case (c) do
      8 -> _this = %{_this.buf | b: "\\b"}
      9 -> _this = %{_this.buf | b: "\\t"}
      10 -> _this = %{_this.buf | b: "\\n"}
      12 -> _this = %{_this.buf | b: "\\f"}
      13 -> _this = %{_this.buf | b: "\\r"}
      34 -> _this = %{_this.buf | b: "\\\""}
      92 -> _this = %{_this.buf | b: "\\\\"}
      _ -> _this = %{_this.buf | b: String.from_char_code(c)}
    end
        ) end)
          _this = %{_this.buf | b: "\""}
        )
  end

end
