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
          printer = Haxe.Format.JsonPrinter.new(replacer, space)
          printer.write("", o)
          printer.buf.b
        )
  end

  # Instance functions
  @doc "Function write"
  @spec write(t(), term(), term()) :: t()
  def write(%__MODULE__{} = struct, k, v) do
    (
          if ((struct.replacer != nil)) do
          v = struct.replacer(k, v)
        end
          (
          g_array = Type.typeof(v)
          case g_array do
      :t_null -> struct = %{struct.buf | b: "null"}
      :t_int -> struct = %{struct.buf | b: Std.string(v)}
      :t_float -> tempString = if Math.is_finite(v), do: Std.string(v), else: "null"
      :t_bool -> struct = %{struct.buf | b: Std.string(v)}
      :t_object -> struct.fields_string(v, Reflect.fields(v))
      :t_function -> struct = %{struct.buf | b: "\"<fun>\""}
      :t_class -> (
          c = g_array
          if ((c == String)) do
          struct.quote_(v)
        else
          if ((c == Array)) do
          v = v
    struct = %{struct.buf | b: "["}
    len = v.length
    last = (len - 1)
    g_counter = 0
    g_array = len
    i = nil
    g3 = nil
    this = nil
    v3 = nil
    loop_helper = fn loop_fn, {i, g3, this, v3} ->
      if ((g_array < g_array)) do
        i = g_array + 1
        if ((i > 0)) do
              struct = %{struct.buf | b: ","}
            else
              struct.nind + 1
            end
        if struct.pretty do
              struct = %{struct.buf | b: "\n"}
            end
        if struct.pretty do
              (
              v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
              struct = %{struct.buf | b: Std.string(v)}
            )
            end
        struct.write(i, Enum.at(v, i))
        if ((i == last)) do
              (
              struct.nind - 1
              if struct.pretty do
              struct = %{struct.buf | b: "\n"}
            end
              if struct.pretty do
              (
              v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
              struct = %{struct.buf | b: Std.string(v)}
            )
            end
            )
            end
        loop_fn.(loop_fn, {i, g3, this, v3})
      else
        {i, g3, this, v3}
      end
    end

    {i, g3, this, v3} = loop_helper.(loop_helper, {i, g3, this, v3})
    struct = %{struct.buf | b: "]"}
        else
          if ((c == StringMap)) do
          (
          v = v
          o = %{}
          k = v.keys()
          k3 = nil
    loop_helper = fn loop_fn, {k3} ->
      if k.has_next() do
        k = k.next()
        Reflect.set_field(o, k, v.get(k))
        loop_fn.(loop_fn, {k3})
      else
        {k3}
      end
    end

    {k3} = loop_helper.(loop_helper, {k3})
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
      :t_enum -> (
          i = Type.enum_index(v)
          (
          v = Std.string(i)
          struct = %{struct.buf | b: Std.string(v)}
        )
        )
      :t_unknown -> struct = %{struct.buf | b: "\"???\""}
    end
        )
        )
    struct
  end

  @doc "Function class_string"
  @spec class_string(t(), term()) :: nil
  def class_string(%__MODULE__{} = struct, v) do
    struct.fields_string(v, Type.get_instance_fields(Type.get_class(v)))
  end

  @doc "Function fields_string"
  @spec fields_string(t(), term(), Array.t()) :: t()
  def fields_string(%__MODULE__{} = struct, v, fields) do
    struct = %{struct.buf | b: "{"}
    len = fields.length
    empty = true
    g_counter = 0
    g_array = len
    i = nil
    g = nil
    f = nil
    value = nil
    empty = nil
    this = nil
    v2 = nil
    loop_helper = fn loop_fn, {i, g, f, value, empty, this, v2} ->
      if ((g_array < g_array)) do
        i = g_array + 1
        f = Enum.at(fields, i)
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
              struct = %{struct.buf | b: ","}
            end
        if struct.pretty do
              struct = %{struct.buf | b: "\n"}
            end
        if struct.pretty do
              (
              v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
              struct = %{struct.buf | b: Std.string(v)}
            )
            end
        struct.quote_(f)
        struct = %{struct.buf | b: ":"}
        if struct.pretty do
              struct = %{struct.buf | b: " "}
            end
        struct.write(f, value)
        loop_fn.(loop_fn, {i, g, f, value, empty, this, v2})
      else
        {i, g, f, value, empty, this, v2}
      end
    end

    {i, g, f, value, empty, this, v2} = loop_helper.(loop_helper, {i, g, f, value, empty, this, v2})
    if (not empty) do
          (
          struct.nind - 1
          if struct.pretty do
          struct = %{struct.buf | b: "\n"}
        end
          if struct.pretty do
          (
          v = StringTools.lpad("", struct.indent, (struct.nind * struct.indent.length))
          struct = %{struct.buf | b: Std.string(v)}
        )
        end
        )
        end
    struct = %{struct.buf | b: "}"}
    struct
  end

  @doc "Function quote_"
  @spec quote_(t(), String.t()) :: t()
  def quote_(%__MODULE__{} = struct, s) do
    (
          struct = %{struct.buf | b: "\""}
          i = 0
          length = s.length
          temp_number = nil
    index = nil
    i = nil
    c = nil
    loop_helper = fn loop_fn, {temp_number, index, i, c} ->
      if ((i < length)) do
        temp_number = nil
        index = i + 1
        temp_number = s.cca(index)
        c = temp_number
        case (elem(c, 0)) do
          8 ->
            struct = %{struct.buf | b: "\\b"}
          9 ->
            struct = %{struct.buf | b: "\\t"}
          10 ->
            struct = %{struct.buf | b: "\\n"}
          12 ->
            struct = %{struct.buf | b: "\\f"}
          13 ->
            struct = %{struct.buf | b: "\\r"}
          34 ->
            struct = %{struct.buf | b: "\\\""}
          92 ->
            struct = %{struct.buf | b: "\\\\"}
          _ -> struct = %{struct.buf | b: String.from_char_code(c)}
        end
        loop_fn.(loop_fn, {temp_number, index, i, c})
      else
        {temp_number, index, i, c}
      end
    end

    {temp_number, index, i, c} = loop_helper.(loop_helper, {temp_number, index, i, c})
          struct = %{struct.buf | b: "\""}
        )
    struct
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
