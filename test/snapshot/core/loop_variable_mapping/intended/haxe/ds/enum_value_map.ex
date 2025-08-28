defmodule EnumValueMap do
  @behaviour IMap

  @moduledoc """
    EnumValueMap struct generated from Haxe

      EnumValueMap allows mapping of enum value keys to arbitrary values.

      Keys are compared by value and recursively over their parameters. If any
      parameter is not an enum value, `Reflect.compare` is used to compare them.
  """

  # Instance functions
  @doc "Generated from Haxe compare"
  def compare(%__MODULE__{} = struct, k1, k2) do
    d = (Type.enum_index(k1) - Type.enum_index(k2))

    if ((d != 0)) do
      d
    else
      nil
    end

    p1 = Type.enum_parameters(k1)

    p2 = Type.enum_parameters(k2)

    if (((p1.length == 0) && (p2.length == 0))) do
      0
    else
      nil
    end

    struct.compare_args(p1, p2)
  end

  @doc "Generated from Haxe compareArgs"
  def compare_args(%__MODULE__{} = struct, a1, a2) do
    ld = (a1.length - a2.length)

    if ((ld != 0)) do
      ld
    else
      nil
    end

    g_counter = 0

    g_array = a1.length

    (fn loop ->
      if ((g_counter < g_array)) do
            i = g_counter + 1
        d = struct.compare_arg(Enum.at(a1, _i), Enum.at(a2, _i))
        if ((d != 0)) do
          d
        else
          nil
        end
        loop.()
      end
    end).()

    0
  end

  @doc "Generated from Haxe compareArg"
  def compare_arg(%__MODULE__{} = struct, v1, v2) do
    temp_result = nil

    temp_result = nil

    if ((Reflect.is_enum_value(v1) && Reflect.is_enum_value(v2))) do
      temp_result = struct.compare(v1, v2)
    else
      if ((Std.is_of_type(v1, Array) && Std.is_of_type(v2, Array))), do: temp_result = struct.compare_args(v1, v2), else: temp_result = Reflect.compare(v1, v2)
    end

    temp_result
  end

  @doc "Generated from Haxe copy"
  def copy(%__MODULE__{} = struct) do
    copied = EnumValueMap.new()

    %{copied | root: struct.root}

    copied
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
