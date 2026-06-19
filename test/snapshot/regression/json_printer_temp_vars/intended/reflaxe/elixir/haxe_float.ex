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
