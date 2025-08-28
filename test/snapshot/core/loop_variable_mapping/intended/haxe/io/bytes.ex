defmodule Bytes do
  @moduledoc """
    Bytes struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:length, :b]

  @type t() :: %__MODULE__{
    length: integer() | nil,
    b: BytesData.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(integer(), BytesData.t()) :: t()
  def new(arg0, arg1) do
    %__MODULE__{
      length: arg0,
      b: arg1
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Static functions
  @doc "Generated from Haxe alloc"
  def alloc(length) do
    a = Array.new()

    g_counter = 0

    g_array = length

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
        fn -> ((g_counter < g_array)) end,
        fn ->
          _i = g_counter + 1
          a ++ [0]
        end,
        loop_helper
      )
    )

    Bytes.new(length, a)
  end

  @doc "Generated from Haxe ofString"
  def of_string(s, _encoding \\ nil) do
    temp_number = nil
    temp_left = nil

    a = Array.new()

    i = 0

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
        fn -> ((g_counter < g_array.length)) end,
        fn ->
          index = g_counter + 1
          temp_number = g_array.cca(index)
          c = temp_number
          if (((55296 <= c) && (c <= 56319))) do
            index = g_counter + 1
            temp_left = g_array.cca(index)
            c = (Bitwise.bsl((c - 55232), 10) or (temp_left and 1023))
          else
            nil
          end
          if ((c <= 127)) do
            a ++ [c]
          else
            if ((c <= 2047)) do
              a ++ [(192 or Bitwise.bsr(c, 6))]
              a ++ [(128 or (c and 63))]
            else
              if ((c <= 65535)) do
                a ++ [(224 or Bitwise.bsr(c, 12))]
                a ++ [(128 or (Bitwise.bsr(c, 6) and 63))]
                a ++ [(128 or (c and 63))]
              else
                a ++ [(240 or Bitwise.bsr(c, 18))]
                a ++ [(128 or (Bitwise.bsr(c, 12) and 63))]
                a ++ [(128 or (Bitwise.bsr(c, 6) and 63))]
                a ++ [(128 or (c and 63))]
              end
            end
          end
        end,
        loop_helper
      )
    )

    Bytes.new(a.length, a)
  end

  @doc "Generated from Haxe ofData"
  def of_data(b) do
    Bytes.new(b.length, b)
  end

  @doc "Generated from Haxe ofHex"
  def of_hex(s) do
    len = s.length

    if ((((len and 1)) != 0)) do
      raise "Not a hex string (odd number of digits)"
    else
      nil
    end

    ret = Bytes.alloc(Bitwise.bsr(len, 1))

    g_counter = 0

    g_array = ret.length

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
        fn -> ((g_counter < g_array)) end,
        fn ->
          i = g_counter + 1
          high = s.cca((i * 2))
          low = s.cca(((i * 2) + 1))
          high = (((high and 15)) + ((Bitwise.bsr(((high and 64)), 6)) * 9))
          low = (((low and 15)) + ((Bitwise.bsr(((low and 64)), 6)) * 9))
          Enum.at(ret.b, i) = ((((Bitwise.bsl(high, 4) or low)) and 255) and 255)
        end,
        loop_helper
      )
    )

    ret
  end

  @doc "Generated from Haxe fastGet"
  def fast_get(_b, _pos) do
    Enum.at(b, pos)
  end

  # Instance functions
  @doc "Generated from Haxe get"
  def get(%__MODULE__{} = struct, _pos) do
    Enum.at(struct.b, pos)
  end

  @doc "Generated from Haxe set"
  def set(%__MODULE__{} = struct, _pos, v) do
    Enum.at(struct.b, pos) = (v and 255)
  end

  @doc "Generated from Haxe blit"
  def blit(%__MODULE__{} = struct, pos, src, srcpos, len) do
    if ((((((pos < 0) || (srcpos < 0)) || (len < 0)) || ((pos + len) > struct.length)) || ((srcpos + len) > src.length))) do
      raise :outside_bounds
    else
      nil
    end

    b1 = struct.b

    b2 = src.b

    if (((b1 == b2) && (pos > srcpos))) do
      i = len
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
          fn -> ((i > 0)) end,
          fn ->
            i - 1
            Enum.at(b1, (i + pos)) = Enum.at(b2, (i + srcpos))
          end,
          loop_helper
        )
      )
      nil
    else
      nil
    end

    g_counter = 0

    g_array = len

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
        fn -> ((g_counter < g_array)) end,
        fn ->
          i = g_counter + 1
          Enum.at(b1, (i + pos)) = Enum.at(b2, (i + srcpos))
        end,
        loop_helper
      )
    )
  end

  @doc "Generated from Haxe fill"
  def fill(%__MODULE__{} = struct, pos, len, value) do
    g_counter = 0

    g_array = len

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
        fn -> ((g_counter < g_array)) end,
        fn ->
          _i = g_counter + 1
          _pos = pos + 1
          Enum.at(struct.b, _pos) = (value and 255)
        end,
        loop_helper
      )
    )
  end

  @doc "Generated from Haxe sub"
  def sub(%__MODULE__{} = struct, pos, len) do
    if ((((pos < 0) || (len < 0)) || ((pos + len) > struct.length))) do
      raise :outside_bounds
    else
      nil
    end

    Bytes.new(len, struct.b.slice(pos, (pos + len)))
  end

  @doc "Generated from Haxe compare"
  def compare(%__MODULE__{} = struct, other) do
    temp_number = nil

    b1 = struct.b

    b2 = other.b

    if ((struct.length < other.length)), do: temp_number = struct.length, else: temp_number = other.length

    len = temp_number

    g_counter = 0

    g_array = len

    b1
    |> Enum.with_index()
    |> Enum.each(fn {item, i} ->
      i = g_counter + 1
      if ((item != Enum.at(b2, i))) do
        (item - Enum.at(b2, i))
      else
        nil
      end
    end)

    (struct.length - other.length)
  end

  @doc "Generated from Haxe getDouble"
  def get_double(%__MODULE__{} = struct, pos) do
    temp_number = nil

    _pos = (pos + 4)

    temp_number = (((Enum.at(struct.b, _pos) or Bitwise.bsl(Enum.at(struct.b, (_pos + 1)), 8)) or Bitwise.bsl(Enum.at(struct.b, (_pos + 2)), 16)) or Bitwise.bsl(Enum.at(struct.b, (_pos + 3)), 24))

    FPHelper.i64_to_double((((Enum.at(struct.b, pos) or Bitwise.bsl(Enum.at(struct.b, (pos + 1)), 8)) or Bitwise.bsl(Enum.at(struct.b, (pos + 2)), 16)) or Bitwise.bsl(Enum.at(struct.b, (pos + 3)), 24)), temp_number)
  end

  @doc "Generated from Haxe getFloat"
  def get_float(%__MODULE__{} = struct, _pos) do
    FPHelper.i32_to_float((((Enum.at(struct.b, pos) or Bitwise.bsl(Enum.at(struct.b, (pos + 1)), 8)) or Bitwise.bsl(Enum.at(struct.b, (pos + 2)), 16)) or Bitwise.bsl(Enum.at(struct.b, (pos + 3)), 24)))
  end

  @doc "Generated from Haxe setDouble"
  def set_double(%__MODULE__{} = struct, pos, v) do
    i = FPHelper.double_to_i64(v)

    v = i.low
    Enum.at(struct.b, pos) = (v and 255)
    Enum.at(struct.b, (pos + 1)) = (Bitwise.bsr(v, 8) and 255)
    Enum.at(struct.b, (pos + 2)) = (Bitwise.bsr(v, 16) and 255)
    Enum.at(struct.b, (pos + 3)) = (Bitwise.bsr(v, 24) and 255)

    _pos = (pos + 4)
    v = i.high
    Enum.at(struct.b, _pos) = (v and 255)
    Enum.at(struct.b, (_pos + 1)) = (Bitwise.bsr(v, 8) and 255)
    Enum.at(struct.b, (_pos + 2)) = (Bitwise.bsr(v, 16) and 255)
    Enum.at(struct.b, (_pos + 3)) = (Bitwise.bsr(v, 24) and 255)
  end

  @doc "Generated from Haxe setFloat"
  def set_float(%__MODULE__{} = struct, _pos, v) do
    v = FPHelper.float_to_i32(v)

    Enum.at(struct.b, pos) = (v and 255)

    Enum.at(struct.b, (pos + 1)) = (Bitwise.bsr(v, 8) and 255)

    Enum.at(struct.b, (pos + 2)) = (Bitwise.bsr(v, 16) and 255)

    Enum.at(struct.b, (pos + 3)) = (Bitwise.bsr(v, 24) and 255)
  end

  @doc "Generated from Haxe getUInt16"
  def get_u_int16(%__MODULE__{} = struct, _pos) do
    (Enum.at(struct.b, pos) or Bitwise.bsl(Enum.at(struct.b, (pos + 1)), 8))
  end

  @doc "Generated from Haxe setUInt16"
  def set_u_int16(%__MODULE__{} = struct, _pos, v) do
    Enum.at(struct.b, pos) = (v and 255)

    Enum.at(struct.b, (pos + 1)) = (Bitwise.bsr(v, 8) and 255)
  end

  @doc "Generated from Haxe getInt32"
  def get_int32(%__MODULE__{} = struct, _pos) do
    (((Enum.at(struct.b, pos) or Bitwise.bsl(Enum.at(struct.b, (pos + 1)), 8)) or Bitwise.bsl(Enum.at(struct.b, (pos + 2)), 16)) or Bitwise.bsl(Enum.at(struct.b, (pos + 3)), 24))
  end

  @doc "Generated from Haxe getInt64"
  def get_int64(%__MODULE__{} = struct, pos) do
    temp_number = nil
    temp_result = nil

    _pos = (pos + 4)

    temp_number = (((Enum.at(struct.b, _pos) or Bitwise.bsl(Enum.at(struct.b, (_pos + 1)), 8)) or Bitwise.bsl(Enum.at(struct.b, (_pos + 2)), 16)) or Bitwise.bsl(Enum.at(struct.b, (_pos + 3)), 24))

    high = temp_number

    low = (((Enum.at(struct.b, pos) or Bitwise.bsl(Enum.at(struct.b, (pos + 1)), 8)) or Bitwise.bsl(Enum.at(struct.b, (pos + 2)), 16)) or Bitwise.bsl(Enum.at(struct.b, (pos + 3)), 24))

    x = Int64.new(high, low)

    temp_result = x

    temp_result
  end

  @doc "Generated from Haxe setInt32"
  def set_int32(%__MODULE__{} = struct, _pos, v) do
    Enum.at(struct.b, pos) = (v and 255)

    Enum.at(struct.b, (pos + 1)) = (Bitwise.bsr(v, 8) and 255)

    Enum.at(struct.b, (pos + 2)) = (Bitwise.bsr(v, 16) and 255)

    Enum.at(struct.b, (pos + 3)) = (Bitwise.bsr(v, 24) and 255)
  end

  @doc "Generated from Haxe setInt64"
  def set_int64(%__MODULE__{} = struct, pos, v) do
    v = v.low

    Enum.at(struct.b, pos) = (v and 255)

    Enum.at(struct.b, (pos + 1)) = (Bitwise.bsr(v, 8) and 255)

    Enum.at(struct.b, (pos + 2)) = (Bitwise.bsr(v, 16) and 255)

    Enum.at(struct.b, (pos + 3)) = (Bitwise.bsr(v, 24) and 255)

    _pos = (pos + 4)

    v = v.high

    Enum.at(struct.b, _pos) = (v and 255)

    Enum.at(struct.b, (_pos + 1)) = (Bitwise.bsr(v, 8) and 255)

    Enum.at(struct.b, (_pos + 2)) = (Bitwise.bsr(v, 16) and 255)

    Enum.at(struct.b, (_pos + 3)) = (Bitwise.bsr(v, 24) and 255)
  end

  @doc "Generated from Haxe getString"
  def get_string(%__MODULE__{} = struct, pos, len, encoding \\ nil) do
    if ((encoding == nil)), do: (encoding == :u_t_f8), else: nil

    if ((((pos < 0) || (len < 0)) || ((pos + len) > struct.length))) do
      raise :outside_bounds
    else
      nil
    end

    s = ""

    _b = struct.b

    fcc = fn code -> &String.from_char_code/1(code) end

    i = pos

    max = (pos + len)

    Enum.each(_b, fn c -> 
      if ((c < 128)) do
      if ((c == 0)) do
        throw(:break)
      else
        nil
      end
      s = s <> fcc.(c)
    else
      if ((c < 224)) do
        s = s <> fcc.((Bitwise.bsl(((c and 63)), 6) or (Enum.at(_b, g_counter + 1) and 127)))
      else
        if ((c < 240)) do
          c2 = Enum.at(_b, g_counter + 1)
          s = s <> fcc.(((Bitwise.bsl(((c and 31)), 12) or Bitwise.bsl(((c2 and 127)), 6)) or (Enum.at(_b, g_counter + 1) and 127)))
        else
          c2 = Enum.at(_b, g_counter + 1)
          c3 = Enum.at(_b, g_counter + 1)
          u = (((Bitwise.bsl(((c and 15)), 18) or Bitwise.bsl(((c2 and 127)), 12)) or Bitwise.bsl(((c3 and 127)), 6)) or (Enum.at(_b, g_counter + 1) and 127))
          s = s <> fcc.(((Bitwise.bsr(u, 10)) + 55232))
          s = s <> fcc.(((u and 1023) or 56320))
        end
      end
    end
    end)

    s
  end

  @doc "Generated from Haxe readString"
  def read_string(%__MODULE__{} = struct, pos, len) do
    struct.get_string(pos, len)
  end

  @doc "Generated from Haxe toString"
  def format(%__MODULE__{} = struct) do
    struct.get_string(0, struct.length)
  end

  @doc "Generated from Haxe toHex"
  def to_hex(%__MODULE__{} = struct) do
    s_b = ""

    chars = []

    str = "0123456789abcdef"

    g_counter = 0
    g_array = str.length
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
        fn -> ((g_counter < g_array)) end,
        fn ->
          i = g_counter + 1
          chars ++ [str.char_code_at(i)]
        end,
        loop_helper
      )
    )

    g_counter = 0
    g_array = struct.length
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
        fn -> ((g_counter < g_array)) end,
        fn ->
          i = g_counter + 1
          c = Enum.at(struct.b, i)
          c = Enum.at(chars, Bitwise.bsr(c, 4))
          s_b = s_b <> String.from_char_code(c)
          c = Enum.at(chars, (c and 15))
          s_b = s_b <> String.from_char_code(c)
        end,
        loop_helper
      )
    )

    s_b
  end

  @doc "Generated from Haxe getData"
  def get_data(%__MODULE__{} = struct) do
    struct.b
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
