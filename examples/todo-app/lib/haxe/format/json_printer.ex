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

    if ((struct.replacer != nil)) do
          v = struct.replacer(k, v)
        end
    temp_string = nil
    g_array = Type.typeof(v)
    case g_array do
      0 -> struct = %{struct.buf | b: "null"}
      1 -> struct = %{struct.buf | b: Std.string(v)}
      2 -> v = temp_string
        _this = %{_this.buf | b: Std.string(v)}
      3 -> struct = %{struct.buf | b: Std.string(v)}
      4 -> struct.fields_string(v, Reflect.fields(v))
      5 -> struct = %{struct.buf | b: "\"<fun>\""}
      6 -> (
    g_array = elem(g_array, 1)
    (
          c = g_array
          if ((c == String)) do
          struct.quote_(v)
        else
          if ((c == Array)) do
          v = v
    _this = %{_this.buf | b: "["}
    len = v.length
    last = (len - 1)
    g_counter = 0
    g_array = len
    v
    |> Enum.with_index()
    |> Enum.each(fn {item, i} ->
      (
            i = g_counter + 1
            if ((i > 0)) do
            _this = %{_this.buf | b: ","}
          else
            struct.nind + 1
          end
            if struct.pretty do
            _this = %{_this.buf | b: "\n"}
          end
            if struct.pretty do
            (
            v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
            _this = %{_this.buf | b: Std.string(v)}
          )
          end
            struct.write(i, item)
            if ((i == last)) do
            (
            struct.nind - 1
            if struct.pretty do
            _this = %{_this.buf | b: "\n"}
          end
            if struct.pretty do
            (
            v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
            _this = %{_this.buf | b: Std.string(v)}
          )
          end
          )
          end
          )
    end)
    _this = %{_this.buf | b: "]"}
        else
          if ((c == StringMap)) do
          (
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
          (
                k = k.next()
                Reflect.set_field(o, k, v.get(k))
              )
        end,
        loop_helper
      )
    )
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
    )
      7 -> (
    g_array = elem(g_array, 1)
    (
          i = Type.enum_index(v)
          (
          v = Std.string(i)
          _this = %{_this.buf | b: Std.string(v)}
        )
        )
    )
      8 -> struct = %{struct.buf | b: "\"???\""}
    end
  end

  @doc "Generated from Haxe classString"
  def class_string(%__MODULE__{} = struct, v) do
    struct.fields_string(v, Type.get_instance_fields(Type.get_class(v)))
  end

  @doc "Generated from Haxe fieldsString"
  def fields_string(%__MODULE__{} = struct, v, fields) do
    _this = %{_this.buf | b: "{"}
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
          end
      if empty do
            (
            struct.nind + 1
            empty = false
          )
          else
            _this = %{_this.buf | b: ","}
          end
      if struct.pretty do
            _this = %{_this.buf | b: "\n"}
          end
      if struct.pretty do
            (
            v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
            _this = %{_this.buf | b: Std.string(v)}
          )
          end
      struct.quote_(f)
      _this = %{_this.buf | b: ":"}
      if struct.pretty do
            _this = %{_this.buf | b: " "}
          end
      struct.write(f, value)
    end)
    if (not empty) do
          (
          struct.nind - 1
          if struct.pretty do
          _this = %{_this.buf | b: "\n"}
        end
          if struct.pretty do
          (
          v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
          _this = %{_this.buf | b: Std.string(v)}
        )
        end
        )
        end
    _this = %{_this.buf | b: "}"}
  end

  @doc "Generated from Haxe quote"
  def quote_(%__MODULE__{} = struct, s) do
    _this = %{_this.buf | b: "\""}
    i = 0
    length = s.length
    for <<char <- s>> do
      char_code = char
      index = g_counter + 1
          case (char_code) do
        _ ->
          struct = %{struct.buf | b: "\\b"}
        _ ->
          struct = %{struct.buf | b: "\\t"}
        _ ->
          struct = %{struct.buf | b: "\\n"}
        _ ->
          struct = %{struct.buf | b: "\\f"}
        _ ->
          struct = %{struct.buf | b: "\\r"}
        _ ->
          struct = %{struct.buf | b: "\\\""}
        _ ->
          struct = %{struct.buf | b: "\\\\"}
        _ -> struct = %{struct.buf | b: String.from_char_code(char_code)}
      end
    end
    _this = %{_this.buf | b: "\""}
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
