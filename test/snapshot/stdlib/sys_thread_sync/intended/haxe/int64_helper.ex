defmodule Int64Helper do
  def parse_string(s_param) do
    s = String.trim(s_param)
    case Integer.parse(s) do
      {i, ""} ->
        if i < -9223372036854775808 or i > 9223372036854775807 do
          raise Reflaxe.Elixir.HaxeThrow, [value: "NumberFormatError"]
        else
          i
        end
      _ -> raise Reflaxe.Elixir.HaxeThrow, [value: "NumberFormatError"]
    end
  end
  def from_float(f) do
    if (Reflaxe.Elixir.HaxeFloat.is_na_n(f) or not Reflaxe.Elixir.HaxeFloat.is_finite(f)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Number is NaN or Infinite"]
    end
    no_fractions = Reflaxe.Elixir.HaxeFloat.sub(f, Reflaxe.Elixir.HaxeFloat.remainder(f, 1))
    if (Reflaxe.Elixir.HaxeFloat.gt(no_fractions, 9007199254740991)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Conversion overflow"]
    end
    if (Reflaxe.Elixir.HaxeFloat.lt(no_fractions, -9007199254740991)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Conversion underflow"]
    end
    trunc(f)
  end
end
