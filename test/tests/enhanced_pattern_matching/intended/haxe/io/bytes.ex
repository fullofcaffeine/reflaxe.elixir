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
  @doc """
    Returns the `Bytes` representation of the given `String`, using the
    specified encoding (UTF-8 by default).
  """
  @spec of_string(String.t(), Null.t()) :: Bytes.t()
  def of_string(s, encoding) do
    (
          a = Array.new()
          i = 0
          while_loop(fn -> ((i < s.length)) end, fn -> (
          temp_number = nil
          (
          index = i + 1
          temp_number = s.cca(index)
        )
          c = temp_number
          if (((55296 <= c) && (c <= 56319))) do
          (
          temp_left = nil
          (
          index = i + 1
          temp_left = s.cca(index)
        )
          c = (Bitwise.bsl((c - 55232), 10) or (temp_left and 1023))
        )
        end
          if ((c <= 127)) do
          a ++ [c]
        else
          if ((c <= 2047)) do
          (
          a ++ [(192 or Bitwise.bsr(c, 6))]
          a ++ [(128 or (c and 63))]
        )
        else
          if ((c <= 65535)) do
          (
          a ++ [(224 or Bitwise.bsr(c, 12))]
          a ++ [(128 or (Bitwise.bsr(c, 6) and 63))]
          a ++ [(128 or (c and 63))]
        )
        else
          (
          a ++ [(240 or Bitwise.bsr(c, 18))]
          a ++ [(128 or (Bitwise.bsr(c, 12) and 63))]
          a ++ [(128 or (Bitwise.bsr(c, 6) and 63))]
          a ++ [(128 or (c and 63))]
        )
        end
        end
        end
        ) end)
          Haxe.Io.Bytes.new(a.length, a)
        )
  end

end
