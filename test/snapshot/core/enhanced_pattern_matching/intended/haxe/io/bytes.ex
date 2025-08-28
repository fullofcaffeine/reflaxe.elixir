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
