defmodule PatternMatchingTest do
  use Bitwise
  @moduledoc """
  PatternMatchingTest module generated from Haxe
  """

  # Static functions
  @doc """
    Basic enum pattern matching

  """
  @spec match_color(Color.t()) :: String.t()
  def match_color(color) do
    temp_result = nil
    case (elem(color, 0)) do
      0 ->
        temp_result = "red"
      1 ->
        temp_result = "green"
      2 ->
        temp_result = "blue"
      3 ->
        _g = elem(color, 1)
    _g = elem(color, 2)
    _g = elem(color, 3)
    r = _g
    g = _g
    b = _g
    temp_result = "rgb(" <> Integer.to_string(r) <> "," <> Integer.to_string(g) <> "," <> Integer.to_string(b) <> ")"
    end
    temp_result
  end

  @doc """
    Option type pattern matching

  """
  @spec match_option(Option.t()) :: String.t()
  def match_option(option) do
    temp_result = nil
    case (elem(option, 0)) do
      0 ->
        temp_result = "none"
      1 ->
        _g = elem(option, 1)
    value = _g
    temp_result = "some(" <> Std.string(value) <> ")"
    end
    temp_result
  end

  @doc """
    Integer pattern matching with guards

  """
  @spec match_int(integer()) :: String.t()
  def match_int(value) do
    temp_result = nil
    case (value) do
      0 ->
        temp_result = "zero"
      1 ->
        temp_result = "one"
      _ ->
        n = value
    if (n < 0) do
      temp_result = "negative"
    else
      n = value
      if (n > 100), do: temp_result = "large", else: temp_result = "other"
    end
    end
    temp_result
  end

  @doc """
    String pattern matching

  """
  @spec match_string(String.t()) :: String.t()
  def match_string(str) do
    temp_result = nil
    case (str) do
      "" ->
        temp_result = "empty"
      "hello" ->
        temp_result = "greeting"
      _ ->
        s = str
    if (String.length(s) > 10), do: temp_result = "long", else: temp_result = "other"
    end
    temp_result
  end

  @doc """
    Array pattern matching

  """
  @spec match_array(Array.t()) :: String.t()
  def match_array(arr) do
    temp_result = nil
    case (length(arr)) do
      0 ->
        temp_result = "empty"
      1 ->
        _g = Enum.at(arr, 0)
    x = _g
    temp_result = "single(" <> Integer.to_string(x) <> ")"
      2 ->
        _g = Enum.at(arr, 0)
    _g = Enum.at(arr, 1)
    x = _g
    y = _g
    temp_result = "pair(" <> Integer.to_string(x) <> "," <> Integer.to_string(y) <> ")"
      3 ->
        _g = Enum.at(arr, 0)
    _g = Enum.at(arr, 1)
    _g = Enum.at(arr, 2)
    x = _g
    y = _g
    z = _g
    temp_result = "triple(" <> Integer.to_string(x) <> "," <> Integer.to_string(y) <> "," <> Integer.to_string(z) <> ")"
      _ ->
        temp_result = "many"
    end
    temp_result
  end

  @doc """
    Nested pattern matching

  """
  @spec match_nested(Option.t()) :: String.t()
  def match_nested(option) do
    temp_result = nil
    case (elem(option, 0)) do
      0 ->
        temp_result = "no color"
      1 ->
        _g = elem(option, 1)
    case (elem(_g, 0)) do
      0 ->
        temp_result = "red color"
      1 ->
        temp_result = "green color"
      2 ->
        temp_result = "blue color"
      3 ->
        _g = elem(_g, 1)
    elem(_g, 2)
    elem(_g, 3)
    r = _g
    _g
    _g
    if (r > 128) do
      temp_result = "bright rgb"
    else
      _g
      _g
      _g
      temp_result = "dark rgb"
    end
    end
    end
    temp_result
  end

  @doc """
    Boolean pattern matching

  """
  @spec match_bool(boolean(), integer()) :: String.t()
  def match_bool(flag, count) do
    temp_result = nil
    if (flag) do
      if (count == 0) do
        temp_result = "true zero"
      else
        n = count
        if (n > 0), do: temp_result = "true positive", else: temp_result = "other combination"
      end
    else
      if (count == 0) do
        temp_result = "false zero"
      else
        n = count
        if (n > 0), do: temp_result = "false positive", else: temp_result = "other combination"
      end
    end
    temp_result
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("Pattern matching compilation test", %{fileName => "Main.hx", lineNumber => 110, className => "PatternMatchingTest", methodName => "main"})
  end

end


defmodule Color do
  @moduledoc """
  Color enum generated from Haxe
  
  
 * Pattern Matching Compilation Test
 * Tests Haxe switch/match expressions → Elixir case statements
 * Converted from framework-based pattern matching tests to snapshot test
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :red |
    :green |
    :blue |
    {:r_g_b, term(), term(), term()}

  @doc "Creates red enum value"
  @spec red() :: :red
  def red(), do: :red

  @doc "Creates green enum value"
  @spec green() :: :green
  def green(), do: :green

  @doc "Creates blue enum value"
  @spec blue() :: :blue
  def blue(), do: :blue

  @doc """
  Creates r_g_b enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec r_g_b(term(), term(), term()) :: {:r_g_b, term(), term(), term()}
  def r_g_b(arg0, arg1, arg2) do
    {:r_g_b, arg0, arg1, arg2}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is red variant"
  @spec is_red(t()) :: boolean()
  def is_red(:red), do: true
  def is_red(_), do: false

  @doc "Returns true if value is green variant"
  @spec is_green(t()) :: boolean()
  def is_green(:green), do: true
  def is_green(_), do: false

  @doc "Returns true if value is blue variant"
  @spec is_blue(t()) :: boolean()
  def is_blue(:blue), do: true
  def is_blue(_), do: false

  @doc "Returns true if value is r_g_b variant"
  @spec is_r_g_b(t()) :: boolean()
  def is_r_g_b({:r_g_b, _}), do: true
  def is_r_g_b(_), do: false

  @doc "Extracts value from r_g_b variant, returns {:ok, value} or :error"
  @spec get_r_g_b_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_r_g_b_value({:r_g_b, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_r_g_b_value(_), do: :error

end


defmodule Option do
  @moduledoc """
  Option enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :none |
    {:some, term()}

  @doc "Creates none enum value"
  @spec none() :: :none
  def none(), do: :none

  @doc """
  Creates some enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec some(term()) :: {:some, term()}
  def some(arg0) do
    {:some, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is none variant"
  @spec is_none(t()) :: boolean()
  def is_none(:none), do: true
  def is_none(_), do: false

  @doc "Returns true if value is some variant"
  @spec is_some(t()) :: boolean()
  def is_some({:some, _}), do: true
  def is_some(_), do: false

  @doc "Extracts value from some variant, returns {:ok, value} or :error"
  @spec get_some_value(t()) :: {:ok, term()} | :error
  def get_some_value({:some, value}), do: {:ok, value}
  def get_some_value(_), do: :error

end
