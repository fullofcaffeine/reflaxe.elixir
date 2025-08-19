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
    printer = Haxe.Format.JsonPrinter.new(replacer, space)
    printer.write("", o)
    printer.buf.b
  end

  # Instance functions
  @doc "Function write"
  @spec write(t(), term(), term()) :: nil
  def write(%__MODULE__{} = struct, k, v) do
    if (struct.replacer != nil), do: v = struct.replacer(k, v), else: nil
    _g = Type.typeof(v)
    case (elem(_g, 0)) do
      0 ->
        _this = struct.buf
        %{_this | b: _this.b <> "null"}
      1 ->
        _this = struct.buf
        %{_this | b: _this.b <> Std.string(v)}
      2 ->
        temp_string = nil
        if (Math.isFinite(v)), do: temp_string = Std.string(v), else: temp_string = "null"
        v = temp_string
        _this = struct.buf
        %{_this | b: _this.b <> Std.string(v)}
      3 ->
        _this = struct.buf
        %{_this | b: _this.b <> Std.string(v)}
      4 ->
        struct.fieldsString(v, Reflect.fields(v))
      5 ->
        _this = struct.buf
        %{_this | b: _this.b <> "\"<fun>\""}
      6 ->
        _g = elem(_g, 1)
        c = _g
        if (c == String) do
          struct.quote(v)
        else
          if (c == Array) do
            v = v
            _this = struct.buf
            %{_this | b: _this.b <> "["}
            len = v.length
            last = len - 1
            _g = 0
            _g = len
            (
              loop_helper = fn loop_fn ->
                if (_g < _g) do
                  try do
                    i = _g = _g + 1
            if (i > 0) do
              _this = struct.buf
              %{_this | b: _this.b <> ","}
            else
              _this.nind + 1
            end
            if (_this.pretty) do
              _this = struct.buf
              %{_this | b: _this.b <> "\n"}
            end
            if (_this.pretty) do
              v = StringTools.lpad("", _this.indent, _this.nind * _this.indent.length)
              _this = struct.buf
              %{_this | b: _this.b <> Std.string(v)}
            end
            struct.write(i, Enum.at(v, i))
            if (i == last) do
              _this.nind - 1
              if (_this.pretty) do
                _this = struct.buf
                %{_this | b: _this.b <> "\n"}
              end
              if (_this.pretty) do
                v = StringTools.lpad("", _this.indent, _this.nind * _this.indent.length)
                _this = struct.buf
                %{_this | b: _this.b <> Std.string(v)}
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
            _this = struct.buf
            %{_this | b: _this.b <> "]"}
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
        elem(_g, 1)
        i = Type.enumIndex(v)
        v = Std.string(i)
        _this = struct.buf
        %{_this | b: _this.b <> Std.string(v)}
      8 ->
        _this = struct.buf
        %{_this | b: _this.b <> "\"???\""}
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
    _this = struct.buf
    _this = %{_this | b: _this.b <> "{"}
    len = fields.length
    empty = true
    _g = 0
    _g = len
    (
      loop_helper = fn loop_fn, {empty} ->
        if (_g < _g) do
          try do
            i = _g = _g + 1
          f = Enum.at(fields, i)
          value = Reflect.field(v, f)
          if (Reflect.isFunction(value)), do: throw(:continue), else: nil
          if (empty) do
      _this.nind + 1
      empty = false
    else
      _this = struct.buf
      _this = %{_this | b: _this.b <> ","}
    end
          if (_this.pretty) do
      _this = struct.buf
      _this = %{_this | b: _this.b <> "\n"}
    end
          if (_this.pretty) do
      v = StringTools.lpad("", _this.indent, _this.nind * _this.indent.length)
      _this = struct.buf
      _this = %{_this | b: _this.b <> Std.string(v)}
    end
          struct.quote(f)
          _this = struct.buf
          _this = %{_this | b: _this.b <> ":"}
          if (_this.pretty) do
      _this = struct.buf
      _this = %{_this | b: _this.b <> " "}
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
      _this.nind - 1
      if (_this.pretty) do
        _this = struct.buf
        _this = %{_this | b: _this.b <> "\n"}
      end
      if (_this.pretty) do
        v = StringTools.lpad("", _this.indent, _this.nind * _this.indent.length)
        _this = struct.buf
        _this = %{_this | b: _this.b <> Std.string(v)}
      end
    end
    _this = struct.buf
    _this = %{_this | b: _this.b <> "}"}
  end

  @doc "Function quote_"
  @spec quote_(t(), String.t()) :: nil
  def quote_(%__MODULE__{} = struct, s) do
    _this = struct.buf
    _this = %{_this | b: _this.b <> "\""}
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
        _this = struct.buf
        %{_this | b: _this.b <> "\\b"}
      9 ->
        _this = struct.buf
        %{_this | b: _this.b <> "\\t"}
      10 ->
        _this = struct.buf
        %{_this | b: _this.b <> "\\n"}
      12 ->
        _this = struct.buf
        %{_this | b: _this.b <> "\\f"}
      13 ->
        _this = struct.buf
        %{_this | b: _this.b <> "\\r"}
      34 ->
        _this = struct.buf
        %{_this | b: _this.b <> "\\\""}
      92 ->
        _this = struct.buf
        %{_this | b: _this.b <> "\\\\"}
      _ ->
        _this = struct.buf
        %{_this | b: _this.b <> String.fromCharCode(c)}
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
    _this = struct.buf
    _this = %{_this | b: _this.b <> "\""}
  end

end
