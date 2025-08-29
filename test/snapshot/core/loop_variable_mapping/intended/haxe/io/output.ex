defmodule Output do
  @moduledoc """
    Output struct generated from Haxe

      An Output is an abstract write. A specific output implementation will only
      have to override the `writeByte` and maybe the `write`, `flush` and `close`
      methods. See `File.write` and `String.write` for two ways of creating an
      Output.
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
  @doc "Generated from Haxe writeByte"
  def write_byte(%__MODULE__{} = struct, _c) do
    raise NotImplementedException.new(nil, nil, %{"fileName" => "haxe/io/Output.hx", "lineNumber" => 47, "className" => "haxe.io.Output", "methodName" => "writeByte"})
  end

  @doc "Generated from Haxe writeBytes"
  def write_bytes(%__MODULE__{} = struct, s, pos, len) do
    if ((((pos < 0) || (len < 0)) || ((pos + len) > s.length))) do
      raise :outside_bounds
    else
      nil
    end

    _b = s.b

    k = len

    (fn loop ->
      if ((k > 0)) do
            struct.write_byte(Enum.at(_b, pos))
        pos + 1
        k - 1
        loop.()
      end
    end).()

    len
  end

  @doc "Generated from Haxe flush"
  def flush(%__MODULE__{} = struct) do
    nil
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

  @doc "Generated from Haxe write"
  def write(%__MODULE__{} = struct, s) do
    l = s.length

    p = 0

    (fn loop ->
      if ((l > 0)) do
            k = struct.write_bytes(s, p, l)
        if ((k == 0)) do
          raise :blocked
        else
          nil
        end
        p = p + k
        l = l - k
        loop.()
      end
    end).()
  end

  @doc "Generated from Haxe writeFullBytes"
  def write_full_bytes(%__MODULE__{} = struct, s, pos, len) do
    (fn loop ->
      if ((len > 0)) do
            k = struct.write_bytes(s, pos, len)
        pos = pos + k
        len = len - k
        loop.()
      end
    end).()
  end

  @doc "Generated from Haxe writeFloat"
  def write_float(%__MODULE__{} = struct, x) do
    struct.write_int32(FPHelper.float_to_i32(x))
  end

  @doc "Generated from Haxe writeDouble"
  def write_double(%__MODULE__{} = struct, x) do
    i64 = FPHelper.double_to_i64(x)

    if struct.big_endian do
      struct.write_int32(i64.high)
      struct.write_int32(i64.low)
    else
      struct.write_int32(i64.low)
      struct.write_int32(i64.high)
    end
  end

  @doc "Generated from Haxe writeInt8"
  def write_int8(%__MODULE__{} = struct, x) do
    if (((x < -128) || (x >= 128))) do
      raise :overflow
    else
      nil
    end

    struct.write_byte((x and 255))
  end

  @doc "Generated from Haxe writeInt16"
  def write_int16(%__MODULE__{} = struct, x) do
    if (((x < -32768) || (x >= 32768))) do
      raise :overflow
    else
      nil
    end

    struct.write_u_int16((x and 65535))
  end

  @doc "Generated from Haxe writeUInt16"
  def write_u_int16(%__MODULE__{} = struct, x) do
    if (((x < 0) || (x >= 65536))) do
      raise :overflow
    else
      nil
    end

    if struct.big_endian do
      struct.write_byte(Bitwise.bsr(x, 8))
      struct.write_byte((x and 255))
    else
      struct.write_byte((x and 255))
      struct.write_byte(Bitwise.bsr(x, 8))
    end
  end

  @doc "Generated from Haxe writeInt24"
  def write_int24(%__MODULE__{} = struct, x) do
    if (((x < -8388608) || (x >= 8388608))) do
      raise :overflow
    else
      nil
    end

    struct.write_u_int24((x and 16777215))
  end

  @doc "Generated from Haxe writeUInt24"
  def write_u_int24(%__MODULE__{} = struct, x) do
    if (((x < 0) || (x >= 16777216))) do
      raise :overflow
    else
      nil
    end

    if struct.big_endian do
      struct.write_byte(Bitwise.bsr(x, 16))
      struct.write_byte((Bitwise.bsr(x, 8) and 255))
      struct.write_byte((x and 255))
    else
      struct.write_byte((x and 255))
      struct.write_byte((Bitwise.bsr(x, 8) and 255))
      struct.write_byte(Bitwise.bsr(x, 16))
    end
  end

  @doc "Generated from Haxe writeInt32"
  def write_int32(%__MODULE__{} = struct, x) do
    if struct.big_endian do
      struct.write_byte(Bitwise.bsr(x, 24))
      struct.write_byte((Bitwise.bsr(x, 16) and 255))
      struct.write_byte((Bitwise.bsr(x, 8) and 255))
      struct.write_byte((x and 255))
    else
      struct.write_byte((x and 255))
      struct.write_byte((Bitwise.bsr(x, 8) and 255))
      struct.write_byte((Bitwise.bsr(x, 16) and 255))
      struct.write_byte(Bitwise.bsr(x, 24))
    end
  end

  @doc "Generated from Haxe prepare"
  def prepare(%__MODULE__{} = struct, _nbytes) do
    nil
  end

  @doc "Generated from Haxe writeInput"
  def write_input(%__MODULE__{} = struct, i, bufsize \\ nil) do
    if ((bufsize == nil)), do: bufsize = 4096, else: nil

    buf = Bytes.alloc(bufsize)

    try do
      (fn loop ->
        if true do
              len = i.read_bytes(buf, 0, bufsize)
          if ((len == 0)) do
            raise :blocked
          else
            nil
          end
          p = 0
          (fn loop ->
            if ((len > 0)) do
                  k = struct.write_bytes(buf, p, len)
              if ((k == 0)) do
                raise :blocked
              else
                nil
              end
              p = p + k
              len = len - k
              loop.()
            end
          end).()
          loop.()
        end
      end).()
    rescue
      %Eof{} = e -> nil
    end
  end

  @doc "Generated from Haxe writeString"
  def write_string(%__MODULE__{} = struct, s, encoding \\ nil) do
    b = Bytes.of_string(s, encoding)

    struct.write_full_bytes(b, 0, b.length)
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
