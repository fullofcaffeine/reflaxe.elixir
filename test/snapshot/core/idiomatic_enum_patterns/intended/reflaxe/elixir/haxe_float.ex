defmodule Reflaxe.Elixir.HaxeFloat do
  import Kernel, except: [to_string: 1], warn: false
  def nan() do
    {__MODULE__, :nan}
  end
  def positive_infinity() do
    {__MODULE__, :positive_infinity}
  end
  def negative_infinity() do
    {__MODULE__, :negative_infinity}
  end
  def is_special(value) do
    
case value do
  {Reflaxe.Elixir.HaxeFloat, tag} when tag in [:nan, :positive_infinity, :negative_infinity] -> true
  _ -> false
end

  end
  def is_haxe_float(value) do
    is_number(value) or Reflaxe.Elixir.HaxeFloat.is_special(value)
  end
  def is_na_n(value) do
    
case value do
  {Reflaxe.Elixir.HaxeFloat, :nan} -> true
  _ -> false
end

  end
  def is_finite(value) do
    
case value do
  value when is_number(value) -> true
  {Reflaxe.Elixir.HaxeFloat, _tag} -> false
  _ -> false
end

  end
  def neg(value) do
    
case value do
  {Reflaxe.Elixir.HaxeFloat, :nan} -> Reflaxe.Elixir.HaxeFloat.nan()
  {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> Reflaxe.Elixir.HaxeFloat.negative_infinity()
  {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> Reflaxe.Elixir.HaxeFloat.positive_infinity()
  value when is_number(value) -> -value
  value -> raise ArithmeticError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
end

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

  end
  def sub(left, right) do
    Reflaxe.Elixir.HaxeFloat.add(left, Reflaxe.Elixir.HaxeFloat.neg(right))
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

  end
  def remainder(left, right) do
    
case {left, right} do
  {{Reflaxe.Elixir.HaxeFloat, _}, _} -> Reflaxe.Elixir.HaxeFloat.nan()
  {_, {Reflaxe.Elixir.HaxeFloat, _}} -> Reflaxe.Elixir.HaxeFloat.nan()
  {left, right} when is_number(left) and is_number(right) ->
    if right == 0, do: Reflaxe.Elixir.HaxeFloat.nan(), else: :math.fmod(left, right)
  {left, right} -> raise ArithmeticError, "expected Haxe Float-compatible values, got: #{inspect({left, right})}"
end

  end
  def eq(left, right) do
    
case {left, right} do
  {{Reflaxe.Elixir.HaxeFloat, :nan}, _} -> false
  {_, {Reflaxe.Elixir.HaxeFloat, :nan}} -> false
  {left, right} -> left == right
end

  end
  def neq(left, right) do
    not Reflaxe.Elixir.HaxeFloat.eq(left, right)
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

  end
  def lte(left, right) do
    Reflaxe.Elixir.HaxeFloat.lt(left, right) or Reflaxe.Elixir.HaxeFloat.eq(left, right)
  end
  def gt(left, right) do
    Reflaxe.Elixir.HaxeFloat.lt(right, left)
  end
  def gte(left, right) do
    Reflaxe.Elixir.HaxeFloat.gt(left, right) or Reflaxe.Elixir.HaxeFloat.eq(left, right)
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

  end
  def parse(value) do
    
case value do
  nil ->
    Reflaxe.Elixir.HaxeFloat.nan()

  value when is_binary(value) ->
    trimmed = String.trim_leading(value)

    case Float.parse(trimmed) do
      {number, _rest} ->
        number

      :error ->
        case Integer.parse(trimmed) do
          {number, _rest} -> number / 1
          :error -> Reflaxe.Elixir.HaxeFloat.nan()
        end
    end

  _ ->
    Reflaxe.Elixir.HaxeFloat.nan()
end

  end
  def encode32(value) do
    
case value do
  {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> <<0, 0, 0x80, 0x7F>>
  {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> <<0, 0, 0x80, 0xFF>>
  {Reflaxe.Elixir.HaxeFloat, :nan} -> <<0, 0, 0xC0, 0x7F>>
  value when is_number(value) -> <<value::float-little-size(32)>>
  value -> raise ArgumentError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
end

  end
  def encode64(value) do
    
case value do
  {Reflaxe.Elixir.HaxeFloat, :positive_infinity} -> <<0, 0, 0, 0, 0, 0, 0xF0, 0x7F>>
  {Reflaxe.Elixir.HaxeFloat, :negative_infinity} -> <<0, 0, 0, 0, 0, 0, 0xF0, 0xFF>>
  {Reflaxe.Elixir.HaxeFloat, :nan} -> <<0, 0, 0, 0, 0, 0, 0xF8, 0x7F>>
  value when is_number(value) -> <<value::float-little-size(64)>>
  value -> raise ArgumentError, "expected a Haxe Float-compatible value, got: #{inspect(value)}"
end

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

  end
end
