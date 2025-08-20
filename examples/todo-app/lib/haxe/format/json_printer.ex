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
    printer = Haxe.Format.JsonPrinter.new(&JsonPrinter.replacer/2, space)
    printer.write("", o)
    printer.buf.b
  end

  # Instance functions
  @doc "Function write"
  @spec write(t(), term(), term()) :: nil
  def write(%__MODULE__{} = struct, k, v) do
    if (struct.replacer != nil), do: v = struct.replacer(k, v), else: nil
    g = Type.typeof(v)
    case (elem(g, 0)) do
      0 ->
        struct = struct.buf
        %{struct | b: struct.b <> "null"}
      1 ->
        struct = struct.buf
        %{struct | b: struct.b <> Std.string(v)}
      2 ->
        nil
        temp_string = if (Math.isFinite(v)), do: Std.string(v), else: "null"
        v = temp_string
        struct = struct.buf
        %{struct | b: struct.b <> Std.string(v)}
      3 ->
        struct = struct.buf
        %{struct | b: struct.b <> Std.string(v)}
      4 ->
        struct.fieldsString(v, Reflect.fields(v))
      5 ->
        struct = struct.buf
        %{struct | b: struct.b <> "\"<fun>\""}
      6 ->
        g = elem(g, 1)
        c = g
        if (c == String) do
          struct.quote(v)
        else
          if (c == Array) do
            v = v
            struct = struct.buf
            %{struct | b: struct.b <> "["}
            len = v.length
            last = len - 1
            g = 0
            g = len
            (
              loop_helper = fn loop_fn ->
                if (g < g) do
                  try do
                    i = g = g + 1
            if (i > 0) do
              struct = struct.buf
              %{struct | b: struct.b <> ","}
            else
              struct.nind + 1
            end
            if (struct.pretty) do
              struct = struct.buf
              %{struct | b: struct.b <> "\n"}
            end
            if (struct.pretty) do
              v = StringTools.lpad("", struct.indent, struct.nind * struct.indent.length)
              struct = struct.buf
              %{struct | b: struct.b <> Std.string(v)}
            end
            struct.write(i, Enum.at(v, i))
            if (i == last) do
              struct.nind - 1
              if (struct.pretty) do
                struct = struct.buf
                %{struct | b: struct.b <> "\n"}
              end
              if (struct.pretty) do
                v = StringTools.lpad("", struct.indent, struct.nind * struct.indent.length)
                struct = struct.buf
                %{struct | b: struct.b <> Std.string(v)}
              end
            end
                    loop_fn.(loop_fn)
                  catch
                    :break -> nil
                    :continue -> loop_fn.(loop_fn)
                  end
                else
                  nil
                end
              end
              try do
                loop_helper.(loop_helper)
              catch
                :break -> nil
              end
            )
            struct = struct.buf
            %{struct | b: struct.b <> "]"}
          else
            if (c == StringMap) do
              v = v
              o = %{}
              k = v.keys()
              (
                loop_helper = fn loop_fn ->
                  if (k.hasNext()) do
                    try do
                      k = k.next()
              Reflect.setField(o, k, v.get(k))
                      loop_fn.(loop_fn)
                    catch
                      :break -> nil
                      :continue -> loop_fn.(loop_fn)
                    end
                  else
                    nil
                  end
                end
                try do
                  loop_helper.(loop_helper)
                catch
                  :break -> nil
                end
              )
              v = o
              struct.fieldsString(v, Reflect.fields(v))
            else
              if (c == Date) do
                v = v
                struct.quote(v.toString())
              else
                struct.classString(v)
              end
            end
          end
        end
      7 ->
        elem(g, 1)
        i = Type.enumIndex(v)
        v = Std.string(i)
        struct = struct.buf
        %{struct | b: struct.b <> Std.string(v)}
      8 ->
        struct = struct.buf
        %{struct | b: struct.b <> "\"???\""}
    end
  end

  @doc "Function class_string"
  @spec class_string(t(), term()) :: nil
  def class_string(%__MODULE__{} = struct, v) do
    struct.fieldsString(v, Type.getInstanceFields(Type.getClass(v)))
  end

  @doc "Function fields_string"
  @spec fields_string(t(), term(), Array.t()) :: nil
  def fields_string(%__MODULE__{} = struct, v, fields) do
    struct = struct.buf
    struct = %{struct | b: struct.b <> "{"}
    len = fields.length
    empty = true
    g = 0
    g = len
    (
      loop_helper = fn loop_fn, {empty} ->
        if (g < g) do
          try do
            i = g = g + 1
          f = Enum.at(fields, i)
          value = Reflect.field(v, f)
          if (Reflect.isFunction(value)), do: throw(:continue), else: nil
          if (empty) do
      struct.nind + 1
      empty = false
    else
      struct = struct.buf
      struct = %{struct | b: struct.b <> ","}
    end
          if (struct.pretty) do
      struct = struct.buf
      struct = %{struct | b: struct.b <> "\n"}
    end
          if (struct.pretty) do
      v = StringTools.lpad("", struct.indent, struct.nind * struct.indent.length)
      struct = struct.buf
      struct = %{struct | b: struct.b <> Std.string(v)}
    end
          struct.quote(f)
          struct = struct.buf
          struct = %{struct | b: struct.b <> ":"}
          if (struct.pretty) do
      struct = struct.buf
      struct = %{struct | b: struct.b <> " "}
    end
          struct.write(f, value)
          loop_fn.({empty})
            loop_fn.(loop_fn, {empty})
          catch
            :break -> {empty}
            :continue -> loop_fn.(loop_fn, {empty})
          end
        else
          {empty}
        end
      end
      {empty} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    if (!empty) do
      struct.nind - 1
      if (struct.pretty) do
        struct = struct.buf
        struct = %{struct | b: struct.b <> "\n"}
      end
      if (struct.pretty) do
        v = StringTools.lpad("", struct.indent, struct.nind * struct.indent.length)
        struct = struct.buf
        struct = %{struct | b: struct.b <> Std.string(v)}
      end
    end
    struct = struct.buf
    struct = %{struct | b: struct.b <> "}"}
  end

  @doc "Function quote_"
  @spec quote_(t(), String.t()) :: nil
  def quote_(%__MODULE__{} = struct, s) do
    struct = struct.buf
    struct = %{struct | b: struct.b <> "\""}
    i = 0
    length = s.length
    (
      loop_helper = fn loop_fn, {temp_number} ->
        if (i < length) do
          try do
            temp_number = nil
          index = i = i + 1
          temp_number = s.cca(index)
          c = temp_number
          case (c) do
      8 ->
        struct = struct.buf
        %{struct | b: struct.b <> "\\b"}
      9 ->
        struct = struct.buf
        %{struct | b: struct.b <> "\\t"}
      10 ->
        struct = struct.buf
        %{struct | b: struct.b <> "\\n"}
      12 ->
        struct = struct.buf
        %{struct | b: struct.b <> "\\f"}
      13 ->
        struct = struct.buf
        %{struct | b: struct.b <> "\\r"}
      34 ->
        struct = struct.buf
        %{struct | b: struct.b <> "\\\""}
      92 ->
        struct = struct.buf
        %{struct | b: struct.b <> "\\\\"}
      _ ->
        struct = struct.buf
        %{struct | b: struct.b <> String.fromCharCode(c)}
    end
          loop_fn.({s.cca(index)})
            loop_fn.(loop_fn, {temp_number})
          catch
            :break -> {temp_number}
            :continue -> loop_fn.(loop_fn, {temp_number})
          end
        else
          {temp_number}
        end
      end
      {temp_number} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    struct = struct.buf
    struct = %{struct | b: struct.b <> "\""}
  end

end
