defmodule BytesBuffer do
  @moduledoc """
    BytesBuffer struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:b]

  @type t() :: %__MODULE__{
    b: Array.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new() :: t()
  def new() do
    %__MODULE__{
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc "Generated from Haxe get_length"
  def get_length(%__MODULE__{} = struct) do
    struct.b.length
  end

  @doc "Generated from Haxe addByte"
  def add_byte(%__MODULE__{} = struct, byte) do
    struct.b ++ [byte]
  end

  @doc "Generated from Haxe add"
  def add(%__MODULE__{} = struct, src) do
    _b1 = struct.b

    b2 = src.b

    g_counter = 0

    g_array = src.length

    b2
    |> Enum.with_index()
    |> Enum.map(fn {item, i} -> item end)
  end

  @doc "Generated from Haxe addString"
  def add_string(%__MODULE__{} = struct, v, encoding \\ nil) do
    src = Bytes.of_string(v, encoding)

    _b1 = struct.b

    b2 = src.b

    g_counter = 0

    g_array = src.length

    b2
    |> Enum.with_index()
    |> Enum.map(fn {item, i} -> item end)
  end

  @doc "Generated from Haxe addInt32"
  def add_int32(%__MODULE__{} = struct, v) do
    struct.b ++ [(v and 255)]

    struct.b ++ [(Bitwise.bsr(v, 8) and 255)]

    struct.b ++ [(Bitwise.bsr(v, 16) and 255)]

    struct.b ++ [Bitwise.bsr(v, 24)]
  end

  @doc "Generated from Haxe addInt64"
  def add_int64(%__MODULE__{} = struct, v) do
    struct.add_int32(v.low)

    struct.add_int32(v.high)
  end

  @doc "Generated from Haxe addFloat"
  def add_float(%__MODULE__{} = struct, v) do
    struct.add_int32(FPHelper.float_to_i32(v))
  end

  @doc "Generated from Haxe addDouble"
  def add_double(%__MODULE__{} = struct, v) do
    struct.add_int64(FPHelper.double_to_i64(v))
  end

  @doc "Generated from Haxe addBytes"
  def add_bytes(%__MODULE__{} = struct, src, pos, len) do
    if ((((pos < 0) || (len < 0)) || ((pos + len) > src.length))) do
      raise :outside_bounds
    else
      nil
    end

    _b1 = struct.b

    b2 = src.b

    g_array = pos

    g_array = (pos + len)

    b2
    |> Enum.with_index()
    |> Enum.map(fn {item, i} -> item end)
  end

  @doc "Generated from Haxe getBytes"
  def get_bytes(%__MODULE__{} = struct) do
    bytes = Bytes.new(struct.b.length, struct.b)

    %{struct | b: nil}

    bytes
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
