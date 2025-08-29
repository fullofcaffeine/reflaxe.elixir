defmodule Input do
  @moduledoc """
    Input struct generated from Haxe

      An Input is an abstract reader. See other classes in the `haxe.io` package
      for several possible implementations.

      All functions which read data throw `Eof` when the end of the stream
      is reached.
  """

  defstruct [:big_endian]

  @type t() :: %__MODULE__{
    big_endian: boolean() | nil
  }

  @doc "Creates a new struct with default values"
  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc "Generated from Haxe readByte"
  def read_byte(%__MODULE__{} = struct) do
    raise NotImplementedException.new(nil, nil, %{"fileName" => "haxe/io/Input.hx", "lineNumber" => 53, "className" => "haxe.io.Input", "methodName" => "readByte"})
  end

  @doc "Generated from Haxe readBytes"
  def read_bytes(%__MODULE__{} = struct, s, pos, len) do
    k = len

    b = s.b

    if ((((pos < 0) || (len < 0)) || ((pos + len) > s.length))) do
      raise :outside_bounds
    else
      nil
    end

    try do
      (fn loop ->
        if ((k > 0)) do
              Enum.at(b, pos) = struct.read_byte()
          pos + 1
          k - 1
          loop.()
        end
      end).()
    rescue
      %Eof{} = eof -> nil
    end

    (len - k)
  end

  @doc "Generated from Haxe close"
  def close(%__MODULE__{} = struct) do
    nil
  end

  @doc "Generated from Haxe set_bigEndian"
  def set_big_endian(%__MODULE__{} = struct, b) do
    %{struct | big_endian: b}

    b
  end

  @doc "Generated from Haxe readAll"
  def read_all(%__MODULE__{} = struct, bufsize \\ nil) do
    if ((bufsize == nil)), do: bufsize = 16384, else: nil

    buf = Bytes.alloc(bufsize)

    total = BytesBuffer.new()

    try do
      (fn loop ->
        if true do
              len = struct.read_bytes(buf, 0, bufsize)
          if ((len == 0)) do
            raise :blocked
          else
            nil
          end
          if (((len < 0) || (len > buf.length))) do
            raise :outside_bounds
          else
            nil
          end
          _b1 = total.b
          b2 = buf.b
          g_counter = 0
          g_array = len
          (fn loop ->
            if ((g_counter < g_array)) do
                  i = g_counter + 1
              total.b ++ [Enum.at(b2, i)]
              loop.()
            end
          end).()
          loop.()
        end
      end).()
    rescue
      %Eof{} = e -> nil
    end

    total.get_bytes()
  end

  @doc "Generated from Haxe readFullBytes"
  def read_full_bytes(%__MODULE__{} = struct, s, pos, len) do
    (fn loop ->
      if ((len > 0)) do
            k = struct.read_bytes(s, pos, len)
        if ((k == 0)) do
          raise :blocked
        else
          nil
        end
        pos = pos + k
        len = len - k
        loop.()
      end
    end).()
  end

  @doc "Generated from Haxe read"
  def read(%__MODULE__{} = struct, nbytes) do
    s = Bytes.alloc(nbytes)

    p = 0

    (fn loop ->
      if ((nbytes > 0)) do
            k = struct.read_bytes(s, p, nbytes)
        if ((k == 0)) do
          raise :blocked
        else
          nil
        end
        p = p + k
        nbytes = nbytes - k
        loop.()
      end
    end).()

    s
  end

  @doc "Generated from Haxe readUntil"
  def read_until(%__MODULE__{} = struct, end_) do
    buf = BytesBuffer.new()

    last = nil

    (fn loop ->
      if true do
            last = struct.read_byte()
        if not ((last != end_)) do
          throw(:break)
        else
          nil
        end
        buf.b ++ [last]
        loop.()
      end
    end).()

    buf.get_bytes().to_string()
  end

  @doc "Generated from Haxe readLine"
  def read_line(%__MODULE__{} = struct) do
    buf = BytesBuffer.new()

    last = nil

    s

    try do
      (fn loop ->
        if true do
              last = struct.read_byte()
          if not ((last != 10)) do
            throw(:break)
          else
            nil
          end
          buf.b ++ [last]
          loop.()
        end
      end).()
      s = buf.get_bytes().to_string()
      if ((s.char_code_at((s.length - 1)) == 13)), do: s = s.substr(0, -1), else: nil
    rescue
      %Eof{} = e -> s = buf.get_bytes().to_string()
      if ((s.length == 0)) do
        raise e
      else
        nil
      end
    end

    s
  end

  @doc "Generated from Haxe readFloat"
  def read_float(%__MODULE__{} = struct) do
    FPHelper.i32_to_float(struct.read_int32())
  end

  @doc "Generated from Haxe readDouble"
  def read_double(%__MODULE__{} = struct) do
    temp_result = nil

    i1 = struct.read_int32()

    i2 = struct.read_int32()

    if struct.big_endian, do: temp_result = FPHelper.i64_to_double(i2, i1), else: temp_result = FPHelper.i64_to_double(i1, i2)

    temp_result
  end

  @doc "Generated from Haxe readInt8"
  def read_int8(%__MODULE__{} = struct) do
    n = struct.read_byte()

    if ((n >= 128)) do
      (n - 256)
    else
      nil
    end

    n
  end

  @doc "Generated from Haxe readInt16"
  def read_int16(%__MODULE__{} = struct) do
    temp_number = nil

    ch1 = struct.read_byte()

    ch2 = struct.read_byte()

    if struct.big_endian, do: temp_number = (ch2 or Bitwise.bsl(ch1, 8)), else: temp_number = (ch1 or Bitwise.bsl(ch2, 8))

    n = temp_number

    if ((((n and 32768)) != 0)) do
      (n - 65536)
    else
      nil
    end

    n
  end

  @doc "Generated from Haxe readUInt16"
  def read_u_int16(%__MODULE__{} = struct) do
    temp_result = nil

    ch1 = struct.read_byte()

    ch2 = struct.read_byte()

    if struct.big_endian, do: temp_result = (ch2 or Bitwise.bsl(ch1, 8)), else: temp_result = (ch1 or Bitwise.bsl(ch2, 8))

    temp_result
  end

  @doc "Generated from Haxe readInt24"
  def read_int24(%__MODULE__{} = struct) do
    temp_number = nil

    ch1 = struct.read_byte()

    ch2 = struct.read_byte()

    ch3 = struct.read_byte()

    if struct.big_endian, do: temp_number = ((ch3 or Bitwise.bsl(ch2, 8)) or Bitwise.bsl(ch1, 16)), else: temp_number = ((ch1 or Bitwise.bsl(ch2, 8)) or Bitwise.bsl(ch3, 16))

    n = temp_number

    if ((((n and 8388608)) != 0)) do
      (n - 16777216)
    else
      nil
    end

    n
  end

  @doc "Generated from Haxe readUInt24"
  def read_u_int24(%__MODULE__{} = struct) do
    temp_result = nil

    ch1 = struct.read_byte()

    ch2 = struct.read_byte()

    ch3 = struct.read_byte()

    if struct.big_endian, do: temp_result = ((ch3 or Bitwise.bsl(ch2, 8)) or Bitwise.bsl(ch1, 16)), else: temp_result = ((ch1 or Bitwise.bsl(ch2, 8)) or Bitwise.bsl(ch3, 16))

    temp_result
  end

  @doc "Generated from Haxe readInt32"
  def read_int32(%__MODULE__{} = struct) do
    temp_result = nil

    ch1 = struct.read_byte()

    ch2 = struct.read_byte()

    ch3 = struct.read_byte()

    ch4 = struct.read_byte()

    if struct.big_endian, do: temp_result = (((ch4 or Bitwise.bsl(ch3, 8)) or Bitwise.bsl(ch2, 16)) or Bitwise.bsl(ch1, 24)), else: temp_result = (((ch1 or Bitwise.bsl(ch2, 8)) or Bitwise.bsl(ch3, 16)) or Bitwise.bsl(ch4, 24))

    temp_result
  end

  @doc "Generated from Haxe readString"
  def read_string(%__MODULE__{} = struct, len, encoding \\ nil) do
    b = Bytes.alloc(len)

    struct.read_full_bytes(b, 0, len)

    b.get_string(0, len, encoding)
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
