defmodule Reflaxe.Elixir.HaxeFloat do
  import Kernel, except: [to_string: 1], warn: false
  def nan() do
    {__MODULE__, :nan}
    item
  end
  def positive_infinity() do
    {__MODULE__, :positive_infinity}
    item
  end
  def negative_infinity() do
    {__MODULE__, :negative_infinity}
    item
  end
  def is_special(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, tag} when tag in [:nan, :positive_infinity, :negative_infinity] -> true
      _ -> false
    end

    item
  end
  def is_haxe_float(value) do
    is_number(value) or Reflaxe.Elixir.HaxeFloat.is_special(value)
    item
  end
  def is_na_n(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :nan} -> true
      _ -> false
    end

    item
  end
  def is_finite(value) do

    case value do
      value when is_number(value) -> true
      {Reflaxe.Elixir.HaxeFloat, _tag} -> false
      _ -> false
    end

    item
  end
  def require_finite_native(value, boundary) do

    case value do
      value when is_number(value) ->
        value

      {Reflaxe.Elixir.HaxeFloat, _tag} ->
        raise ArgumentError,
          "expected finite native Elixir number for " <>
            Kernel.to_string(boundary) <>
            ", received Haxe Float " <>
            Reflaxe.Elixir.HaxeFloat.to_string(value)

      value ->
        raise ArgumentError,
          "expected finite native Elixir number for " <>
            Kernel.to_string(boundary) <>
            ", received " <>
            inspect(value)
    end

    item
  end
  def neg(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :nan} -> Reflaxe.Elixir.HaxeFloat.nan()
      {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> Reflaxe.Elixir.HaxeFloat.negative_infinity()
      {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
      value when is_number(value) -> -value
      value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def add(left, right) do

    case {left, right} do
      {{Reflaxe.Elixir.HaxeFloat, :nan}, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      {_, {Reflaxe.Elixir.HaxeFloat, :nan}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {{Reflaxe.Elixir.HaxeFloat, :positive_infinity}, {Reflaxe.Elixir.HaxeFloat, :negative_infinity}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {{Reflaxe.Elixir.HaxeFloat, :negative_infinity}, {Reflaxe.Elixir.HaxeFloat, :positive_infinity}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {{Reflaxe.Elixir.HaxeFloat, :positive_infinity}, _} -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
      {_, {Reflaxe.Elixir.HaxeFloat, :positive_infinity}} -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
      {{Reflaxe.Elixir.HaxeFloat, :negative_infinity}, _} -> Reflaxe.Elixir.HaxeFloat.negative_infinity()
      {_, {Reflaxe.Elixir.HaxeFloat, :negative_infinity}} -> Reflaxe.Elixir.HaxeFloat.negative_infinity()
      {left, right} when is_number(left) and is_number(right) -> left + right
      {left, right} -> raise ArithmeticError, "expected Haxe Float-compatible values, got: #{inspect({left, right})}"
    end

    item
  end
  def sub(left, right) do
    Reflaxe.Elixir.HaxeFloat.add(left, Reflaxe.Elixir.HaxeFloat.neg(right))
    item
  end
  def mul(left, right) do

    sign = fn
      {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> -1
      value when is_number(value) and value < 0 -> -1
      _ -> 1
    end

    zero? = fn
      value when is_number(value) -> value == 0
      _ -> false
    end

    case {left, right} do
      {{Reflaxe.Elixir.HaxeFloat, :nan}, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      {_, {Reflaxe.Elixir.HaxeFloat, :nan}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {{Reflaxe.Elixir.HaxeFloat, infinity}, value} when infinity in [:positive_infinity, :negative_infinity] ->
        if zero?.(value), do: Reflaxe.Elixir.HaxeFloat.nan(), else: if(sign.(left) * sign.(value) < 0, do: Reflaxe.Elixir.HaxeFloat.negative_infinity(), else: Reflaxe.Elixir.HaxeFloat.positive_infinity())
      {value, {Reflaxe.Elixir.HaxeFloat, infinity}} when infinity in [:positive_infinity, :negative_infinity] ->
        if zero?.(value), do: Reflaxe.Elixir.HaxeFloat.nan(), else: if(sign.(value) * sign.(right) < 0, do: Reflaxe.Elixir.HaxeFloat.negative_infinity(), else: Reflaxe.Elixir.HaxeFloat.positive_infinity())
      {left, right} when is_number(left) and is_number(right) -> left * right
      {left, right} -> raise ArithmeticError, "expected Haxe Float-compatible values, got: #{inspect({left, right})}"
    end

    item
  end
  def divide(left, right) do

    sign = fn
      {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> -1
      value when is_number(value) and value < 0 -> -1
      _ -> 1
    end

    case {left, right} do
      {{Reflaxe.Elixir.HaxeFloat, :nan}, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      {_, {Reflaxe.Elixir.HaxeFloat, :nan}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {{Reflaxe.Elixir.HaxeFloat, infinity}, {Reflaxe.Elixir.HaxeFloat, other_infinity}} when infinity in [:positive_infinity, :negative_infinity] and other_infinity in [:positive_infinity, :negative_infinity] ->
        Reflaxe.Elixir.HaxeFloat.nan()
      {{Reflaxe.Elixir.HaxeFloat, infinity}, right} when infinity in [:positive_infinity, :negative_infinity] and is_number(right) ->
        if right == 0, do: Reflaxe.Elixir.HaxeFloat.nan(), else: if(sign.(left) * sign.(right) < 0, do: Reflaxe.Elixir.HaxeFloat.negative_infinity(), else: Reflaxe.Elixir.HaxeFloat.positive_infinity())
      {left, {Reflaxe.Elixir.HaxeFloat, infinity}} when is_number(left) and infinity in [:positive_infinity, :negative_infinity] ->
        if sign.(left) * sign.(right) < 0, do: -0.0, else: 0.0
      {left, right} when is_number(left) and is_number(right) ->
        cond do
          left == 0 and right == 0 -> Reflaxe.Elixir.HaxeFloat.nan()
          right == 0 and sign.(left) * sign.(right) < 0 -> Reflaxe.Elixir.HaxeFloat.negative_infinity()
          right == 0 -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
          true -> left / right
        end
      {left, right} -> raise ArithmeticError, "expected Haxe Float-compatible values, got: #{inspect({left, right})}"
    end

    item
  end
  def remainder(left, right) do

    case {left, right} do
      {{Reflaxe.Elixir.HaxeFloat, _}, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      {_, {Reflaxe.Elixir.HaxeFloat, _}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {left, right} when is_number(left) and is_number(right) ->
        if right == 0, do: Reflaxe.Elixir.HaxeFloat.nan(), else: :math.fmod(left, right)
      {left, right} -> raise ArithmeticError, "expected Haxe Float-compatible values, got: #{inspect({left, right})}"
    end

    item
  end
  def eq(left, right) do

    case {left, right} do
      {{Reflaxe.Elixir.HaxeFloat, :nan}, _} -> false
      {_, {Reflaxe.Elixir.HaxeFloat, :nan}} -> false
      {left, right} -> left == right
    end

    item
  end
  def neq(left, right) do
    not Reflaxe.Elixir.HaxeFloat.eq(left, right)
    item
  end
  def lt(left, right) do

    case {left, right} do
      {{Reflaxe.Elixir.HaxeFloat, :nan}, _} -> false
      {_, {Reflaxe.Elixir.HaxeFloat, :nan}} -> false
      {{Reflaxe.Elixir.HaxeFloat, :negative_infinity}, {Reflaxe.Elixir.HaxeFloat, :negative_infinity}} -> false
      {{Reflaxe.Elixir.HaxeFloat, :negative_infinity}, _} -> true
      {_, {Reflaxe.Elixir.HaxeFloat, :positive_infinity}} when left != {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> true
      {{Reflaxe.Elixir.HaxeFloat, :positive_infinity}, _} -> false
      {_, {Reflaxe.Elixir.HaxeFloat, :negative_infinity}} -> false
      {left, right} when is_number(left) and is_number(right) -> left < right
      _ -> false
    end

    item
  end
  def lte(left, right) do
    Reflaxe.Elixir.HaxeFloat.lt(left, right) or Reflaxe.Elixir.HaxeFloat.eq(left, right)
    item
  end
  def gt(left, right) do
    Reflaxe.Elixir.HaxeFloat.lt(right, left)
    item
  end
  def gte(left, right) do
    Reflaxe.Elixir.HaxeFloat.gt(left, right) or Reflaxe.Elixir.HaxeFloat.eq(left, right)
    item
  end
  def abs(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :nan} -> Reflaxe.Elixir.HaxeFloat.nan()
      {Reflaxe.Elixir.HaxeFloat, infinity} when infinity in [:positive_infinity, :negative_infinity] ->
        Reflaxe.Elixir.HaxeFloat.positive_infinity()
      value when is_number(value) -> Kernel.abs(value)
      value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def min(left, right) do

    case {left, right} do
      {{Reflaxe.Elixir.HaxeFloat, :nan}, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      {_, {Reflaxe.Elixir.HaxeFloat, :nan}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {left, right} -> if Reflaxe.Elixir.HaxeFloat.lte(left, right), do: left, else: right
    end

    item
  end
  def max(left, right) do

    case {left, right} do
      {{Reflaxe.Elixir.HaxeFloat, :nan}, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      {_, {Reflaxe.Elixir.HaxeFloat, :nan}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {left, right} -> if Reflaxe.Elixir.HaxeFloat.gte(left, right), do: left, else: right
    end

    item
  end
  def sin(value) do
    Reflaxe.Elixir.HaxeFloat.unary_math(value, &:math.sin/1)
    item
  end
  def cos(value) do
    Reflaxe.Elixir.HaxeFloat.unary_math(value, &:math.cos/1)
    item
  end
  def tan(value) do
    Reflaxe.Elixir.HaxeFloat.unary_math(value, &:math.tan/1)
    item
  end
  def acos(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      value when is_number(value) and value >= -1 and value <= 1 -> Reflaxe.Elixir.HaxeFloat.canonicalize(:math.acos(value))
      value when is_number(value) -> Reflaxe.Elixir.HaxeFloat.nan()
      value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def asin(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      value when is_number(value) and value >= -1 and value <= 1 -> Reflaxe.Elixir.HaxeFloat.canonicalize(:math.asin(value))
      value when is_number(value) -> Reflaxe.Elixir.HaxeFloat.nan()
      value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def atan(value) do
    Reflaxe.Elixir.HaxeFloat.unary_math(value, &:math.atan/1)
    item
  end
  def atan2(y, x) do

    case {y, x} do
      {{Reflaxe.Elixir.HaxeFloat, :nan}, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      {_, {Reflaxe.Elixir.HaxeFloat, :nan}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {{Reflaxe.Elixir.HaxeFloat, _}, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      {_, {Reflaxe.Elixir.HaxeFloat, _}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {y, x} when is_number(y) and is_number(x) -> Reflaxe.Elixir.HaxeFloat.canonicalize(:math.atan2(y, x))
      {y, x} -> raise ArithmeticError, "expected Haxe Float-compatible values, got: #{inspect({y, x})}"
    end

    item
  end
  def exp(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :nan} -> Reflaxe.Elixir.HaxeFloat.nan()
      {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
      {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> 0.0
      value when is_number(value) -> :math.exp(value)
      value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def log(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :nan} -> Reflaxe.Elixir.HaxeFloat.nan()
      {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
      {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> Reflaxe.Elixir.HaxeFloat.nan()
      value when is_number(value) and value == 0 -> Reflaxe.Elixir.HaxeFloat.negative_infinity()
      value when is_number(value) and value < 0 -> Reflaxe.Elixir.HaxeFloat.nan()
      value when is_number(value) -> :math.log(value)
      value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def pow(base, exponent) do

    case {base, exponent} do
      {{Reflaxe.Elixir.HaxeFloat, :nan}, _} -> Reflaxe.Elixir.HaxeFloat.nan()
      {_, {Reflaxe.Elixir.HaxeFloat, :nan}} -> Reflaxe.Elixir.HaxeFloat.nan()
      {base, exponent} when is_number(base) and is_number(exponent) ->
        try do
          :math.pow(base, exponent)
        rescue
          ArithmeticError -> Reflaxe.Elixir.HaxeFloat.nan()
        end
      {base, exponent} ->
        cond do
          base == {Reflaxe.Elixir.HaxeFloat, :positive_infinity} and is_number(exponent) and exponent > 0 -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
          base == {Reflaxe.Elixir.HaxeFloat, :positive_infinity} and is_number(exponent) and exponent < 0 -> 0.0
          base == {Reflaxe.Elixir.HaxeFloat, :negative_infinity} and is_number(exponent) and exponent > 0 -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
          base == {Reflaxe.Elixir.HaxeFloat, :negative_infinity} and is_number(exponent) and exponent < 0 -> 0.0
          is_number(base) and exponent == {Reflaxe.Elixir.HaxeFloat, :positive_infinity} and Kernel.abs(base) > 1 -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
          is_number(base) and exponent == {Reflaxe.Elixir.HaxeFloat, :positive_infinity} and Kernel.abs(base) < 1 -> 0.0
          is_number(base) and exponent == {Reflaxe.Elixir.HaxeFloat, :negative_infinity} and Kernel.abs(base) > 1 -> 0.0
          is_number(base) and exponent == {Reflaxe.Elixir.HaxeFloat, :negative_infinity} and Kernel.abs(base) < 1 -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
          true -> Reflaxe.Elixir.HaxeFloat.nan()
        end
    end

    item
  end
  def sqrt(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :nan} -> Reflaxe.Elixir.HaxeFloat.nan()
      {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
      {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> Reflaxe.Elixir.HaxeFloat.nan()
      value when is_number(value) and value < 0 -> Reflaxe.Elixir.HaxeFloat.nan()
      value when is_number(value) -> :math.sqrt(value)
      value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def round_int(value) do

    case value do
      value when is_number(value) -> trunc(:math.floor(value + 0.5))
      value -> raise ArithmeticError, "Math.round is undefined for non-finite Haxe Float value: #{inspect(value)}"
    end

    item
  end
  def floor_int(value) do

    case value do
      value when is_number(value) -> floor(value)
      value -> raise ArithmeticError, "Math.floor is undefined for non-finite Haxe Float value: #{inspect(value)}"
    end

    item
  end
  def ceil_int(value) do

    case value do
      value when is_number(value) -> ceil(value)
      value -> raise ArithmeticError, "Math.ceil is undefined for non-finite Haxe Float value: #{inspect(value)}"
    end

    item
  end
  def ffloor(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :nan} -> Reflaxe.Elixir.HaxeFloat.nan()
      {Reflaxe.Elixir.HaxeFloat, infinity} when infinity in [:positive_infinity, :negative_infinity] -> value
      value when is_number(value) -> :math.floor(value)
      value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def fceil(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :nan} -> Reflaxe.Elixir.HaxeFloat.nan()
      {Reflaxe.Elixir.HaxeFloat, infinity} when infinity in [:positive_infinity, :negative_infinity] -> value
      value when is_number(value) -> :math.ceil(value)
      value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def fround(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :nan} -> Reflaxe.Elixir.HaxeFloat.nan()
      {Reflaxe.Elixir.HaxeFloat, infinity} when infinity in [:positive_infinity, :negative_infinity] -> value
      value when is_number(value) -> :math.floor(value + 0.5)
      value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def canonicalize(value) do

    epsilon = 1.0e-12

    case value do
      value when is_number(value) and Kernel.abs(value) < epsilon -> 0.0
      value when is_number(value) and Kernel.abs(value - 1.0) < epsilon -> 1.0
      value when is_number(value) and Kernel.abs(value + 1.0) < epsilon -> -1.0
      value -> value
    end

    item
  end
  def unary_math(value, function_value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, _} ->
        Reflaxe.Elixir.HaxeFloat.nan()

      value when is_number(value) ->
        try do
          Reflaxe.Elixir.HaxeFloat.canonicalize(function_value.(value))
        rescue
          ArithmeticError -> Reflaxe.Elixir.HaxeFloat.nan()
        end

      value ->
        raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def to_string(value) do

    case value do
      nil -> "null"
      value when is_binary(value) -> value
      {Reflaxe.Elixir.HaxeFloat, :nan} -> "NaN"
      {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> "Infinity"
      {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> "-Infinity"
      value when is_atom(value) -> Atom.to_string(value)
      value when is_number(value) or is_boolean(value) -> Kernel.to_string(value)
      value -> inspect(value)
    end

    item
  end
  def parse(value) do

    case value do
      nil ->
        Reflaxe.Elixir.HaxeFloat.nan()

      value when is_binary(value) ->
        trimmed = String.trim_leading(value)
        numeric_prefix =
          case Regex.run(~r/^[+-]?(?:(?:\d+\.\d*)|(?:\.\d+)|(?:\d+))(?:[eE][+-]?\d+)?/, trimmed) do
            [prefix | _] -> prefix
            _ -> nil
          end

        if Kernel.is_nil(numeric_prefix) do
          Reflaxe.Elixir.HaxeFloat.nan()
        else
          parse_text =
            cond do
              String.starts_with?(numeric_prefix, "+.") -> "+0" <> String.slice(numeric_prefix, 1..-1//1)
              String.starts_with?(numeric_prefix, "-.") -> "-0" <> String.slice(numeric_prefix, 1..-1//1)
              String.starts_with?(numeric_prefix, ".") -> "0" <> numeric_prefix
              true -> numeric_prefix
            end

          case Float.parse(parse_text) do
            {number, _rest} ->
              number

            :error ->
              if String.starts_with?(numeric_prefix, "-") do
                Reflaxe.Elixir.HaxeFloat.negative_infinity()
              else
                Reflaxe.Elixir.HaxeFloat.positive_infinity()
              end
          end
        end

      _ ->
        Reflaxe.Elixir.HaxeFloat.nan()
    end

    item
  end
  def encode32(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> <<0, 0, 0x80, 0x7F>>
      {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> <<0, 0, 0x80, 0xFF>>
      {Reflaxe.Elixir.HaxeFloat, :nan} -> <<0, 0, 0xC0, 0x7F>>
      value when is_number(value) -> <<value::float-little-size(32)>>
      value -> raise ArgumentError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def encode64(value) do

    case value do
      {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> <<0, 0, 0, 0, 0, 0, 0xF0, 0x7F>>
      {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> <<0, 0, 0, 0, 0, 0, 0xF0, 0xFF>>
      {Reflaxe.Elixir.HaxeFloat, :nan} -> <<0, 0, 0, 0, 0, 0, 0xF8, 0x7F>>
      value when is_number(value) -> <<value::float-little-size(64)>>
      value -> raise ArgumentError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
    end

    item
  end
  def decode32(bytes) do

    <<bits::little-unsigned-size(32)>> = bytes
    exponent = Bitwise.band(Bitwise.bsr(bits, 23), 0xFF)
    fraction = Bitwise.band(bits, 0x7FFFFF)
    sign = Bitwise.band(Bitwise.bsr(bits, 31), 1)

    cond do
      exponent == 0xFF and fraction == 0 and sign == 0 ->
        Reflaxe.Elixir.HaxeFloat.positive_infinity()

      exponent == 0xFF and fraction == 0 and sign == 1 ->
        Reflaxe.Elixir.HaxeFloat.negative_infinity()

      exponent == 0xFF ->
        Reflaxe.Elixir.HaxeFloat.nan()

      true ->
        <<value::float-little-size(32)>> = bytes
        value
    end

    item
  end
  def decode64(bytes) do

    <<bits::little-unsigned-size(64)>> = bytes
    exponent = Bitwise.band(Bitwise.bsr(bits, 52), 0x7FF)
    fraction = Bitwise.band(bits, 0xFFFFFFFFFFFFF)
    sign = Bitwise.band(Bitwise.bsr(bits, 63), 1)

    cond do
      exponent == 0x7FF and fraction == 0 and sign == 0 ->
        Reflaxe.Elixir.HaxeFloat.positive_infinity()

      exponent == 0x7FF and fraction == 0 and sign == 1 ->
        Reflaxe.Elixir.HaxeFloat.negative_infinity()

      exponent == 0x7FF ->
        Reflaxe.Elixir.HaxeFloat.nan()

      true ->
        <<value::float-little-size(64)>> = bytes
        value
    end

    item
  end
end
