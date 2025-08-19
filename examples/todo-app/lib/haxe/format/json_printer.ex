defmodule JsonPrinter do
  @moduledoc """
    JsonPrinter module generated from Haxe

      An implementation of JSON printer in Haxe.

      This class is used by `haxe.Json` when native JSON implementation
      is not available.

      @see https://haxe.org/manual/std-Json-encoding.html
  """

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
  @spec write(term(), term()) :: nil
  def write(k, v) do
    if (__MODULE__.replacer != nil), do: v = __MODULE__.replacer(k, v), else: nil
    _g = Type.typeof(v)
    case (elem(_g, 0)) do
      0 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> "null"
      1 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> Std.string(v)
      2 ->
        temp_string = nil
        if (Math.isFinite(v)), do: temp_string = Std.string(v), else: temp_string = "null"
        v = temp_string
        _this = __MODULE__.buf
        _this.b = _this.b <> Std.string(v)
      3 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> Std.string(v)
      4 ->
        __MODULE__.fieldsString(v, Reflect.fields(v))
      5 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> "\"<fun>\""
      6 ->
        _g = elem(_g, 1)
        c = _g
        if (c == String) do
          __MODULE__.quote(v)
        else
          if (c == Array) do
            v = v
            _this = __MODULE__.buf
            _this.b = _this.b <> "["
            len = length(v)
            last = len - 1
            _g = 0
            _g = len
            (
              try do
                loop_fn = fn ->
                  if (_g < _g) do
                    try do
                      i = _g = _g + 1
            if (i > 0) do
              _this = __MODULE__.buf
              _this.b = _this.b <> ","
            else
              __MODULE__.nind + 1
            end
            if (__MODULE__.pretty) do
              _this = __MODULE__.buf
              _this.b = _this.b <> "\n"
            end
            if (__MODULE__.pretty) do
              v = StringTools.lpad("", __MODULE__.indent, __MODULE__.nind * String.length(__MODULE__.indent))
              _this = __MODULE__.buf
              _this.b = _this.b <> Std.string(v)
            end
            __MODULE__.write(i, Enum.at(v, i))
            if (i == last) do
              __MODULE__.nind - 1
              if (__MODULE__.pretty) do
                _this = __MODULE__.buf
                _this.b = _this.b <> "\n"
              end
              if (__MODULE__.pretty) do
                v = StringTools.lpad("", __MODULE__.indent, __MODULE__.nind * String.length(__MODULE__.indent))
                _this = __MODULE__.buf
                _this.b = _this.b <> Std.string(v)
              end
            end
                      loop_fn.()
                    catch
                      :break -> nil
                      :continue -> loop_fn.()
                    end
                  end
                end
                loop_fn.()
              catch
                :break -> nil
              end
            )
            _this = __MODULE__.buf
            _this.b = _this.b <> "]"
          else
            if (c == StringMap) do
              v = v
              o = %{}
              k = v.keys()
              (
                try do
                  loop_fn = fn ->
                    if (k.hasNext()) do
                      try do
                        k = k.next()
              Reflect.setField(o, k, v.get(k))
                        loop_fn.()
                      catch
                        :break -> nil
                        :continue -> loop_fn.()
                      end
                    end
                  end
                  loop_fn.()
                catch
                  :break -> nil
                end
              )
              v = o
              __MODULE__.fieldsString(v, Reflect.fields(v))
            else
              if (c == Date) do
                v = v
                __MODULE__.quote(v.toString())
              else
                __MODULE__.classString(v)
              end
            end
          end
        end
      7 ->
        elem(_g, 1)
        i = Type.enumIndex(v)
        v = Std.string(i)
        _this = __MODULE__.buf
        _this.b = _this.b <> Std.string(v)
      8 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> "\"???\""
    end
  end

  @doc "Function class_string"
  @spec class_string(term()) :: nil
  def class_string(v) do
    __MODULE__.fieldsString(v, Type.getInstanceFields(Type.getClass(v)))
  end

  @doc "Function fields_string"
  @spec fields_string(term(), Array.t()) :: nil
  def fields_string(v, fields) do
    _this = __MODULE__.buf
    _this.b = _this.b <> "{"
    len = length(fields)
    empty = true
    _g = 0
    _g = len
    (
      try do
        loop_fn = fn {empty} ->
          if (_g < _g) do
            try do
              i = _g = _g + 1
          f = Enum.at(fields, i)
          value = Reflect.field(v, f)
          if (Reflect.isFunction(value)), do: throw(:continue), else: nil
          if (empty) do
      __MODULE__.nind + 1
      empty = false
    else
      _this = __MODULE__.buf
      _this.b = _this.b <> ","
    end
          if (__MODULE__.pretty) do
      _this = __MODULE__.buf
      _this.b = _this.b <> "\n"
    end
          if (__MODULE__.pretty) do
      v = StringTools.lpad("", __MODULE__.indent, __MODULE__.nind * String.length(__MODULE__.indent))
      _this = __MODULE__.buf
      _this.b = _this.b <> Std.string(v)
    end
          __MODULE__.quote(f)
          _this = __MODULE__.buf
          _this.b = _this.b <> ":"
          if (__MODULE__.pretty) do
      _this = __MODULE__.buf
      _this.b = _this.b <> " "
    end
          __MODULE__.write(f, value)
          loop_fn.({empty})
            catch
              :break -> {empty}
              :continue -> loop_fn.({empty})
            end
          else
            {empty}
          end
        end
        loop_fn.({empty})
      catch
        :break -> {empty}
      end
    )
    if (!empty) do
      __MODULE__.nind - 1
      if (__MODULE__.pretty) do
        _this = __MODULE__.buf
        _this.b = _this.b <> "\n"
      end
      if (__MODULE__.pretty) do
        v = StringTools.lpad("", __MODULE__.indent, __MODULE__.nind * String.length(__MODULE__.indent))
        _this = __MODULE__.buf
        _this.b = _this.b <> Std.string(v)
      end
    end
    _this = __MODULE__.buf
    _this.b = _this.b <> "}"
  end

  @doc "Function quote_"
  @spec quote_(String.t()) :: nil
  def quote_(s) do
    _this = __MODULE__.buf
    _this.b = _this.b <> "\""
    i = 0
    length = String.length(s)
    (
      try do
        loop_fn = fn {tempNumber} ->
          if (i < length) do
            try do
              temp_number = nil
          index = i = i + 1
          # tempNumber updated to s.cca(index)
          c = temp_number
          case (c) do
      8 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> "\\b"
      9 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> "\\t"
      10 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> "\\n"
      12 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> "\\f"
      13 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> "\\r"
      34 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> "\\\""
      92 ->
        _this = __MODULE__.buf
        _this.b = _this.b <> "\\\\"
      _ ->
        _this = __MODULE__.buf
        _this.b = _this.b <> String.fromCharCode(c)
    end
          loop_fn.({s.cca(index)})
            catch
              :break -> {tempNumber}
              :continue -> loop_fn.({tempNumber})
            end
          else
            {tempNumber}
          end
        end
        loop_fn.({tempNumber})
      catch
        :break -> {tempNumber}
      end
    )
    _this = __MODULE__.buf
    _this.b = _this.b <> "\""
  end

end
