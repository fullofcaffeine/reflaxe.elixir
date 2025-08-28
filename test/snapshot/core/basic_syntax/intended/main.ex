defmodule Main do
  @moduledoc """
    Main struct generated from Haxe

     * Basic syntax test case
     * Tests fundamental Haxe→Elixir compilation
  """

  defstruct [:instance_var, c_o_n_s_t_a_n_t: 0, static_var: ""]

  @type t() :: %__MODULE__{
    instance_var: integer() | nil,
    c_o_n_s_t_a_n_t: integer(),
    static_var: String.t()
  }

  @doc "Creates a new struct instance"
  @spec new(integer()) :: t()
  def new(arg0) do
    %__MODULE__{
      instance_var: arg0,
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Static functions
  @doc "Generated from Haxe greet"
  def greet(name) do
    "Hello, " <> name <> "!"
  end

  @doc "Generated from Haxe main"
  def main() do
    instance = Main.new(10)

    Log.trace(Main.greet("World"), %{"fileName" => "Main.hx", "lineNumber" => 76, "className" => "Main", "methodName" => "main"})

    Log.trace(instance.calculate(5, 3), %{"fileName" => "Main.hx", "lineNumber" => 77, "className" => "Main", "methodName" => "main"})

    Log.trace(instance.check_value(-5), %{"fileName" => "Main.hx", "lineNumber" => 78, "className" => "Main", "methodName" => "main"})

    Log.trace(instance.sum_range(1, 10), %{"fileName" => "Main.hx", "lineNumber" => 79, "className" => "Main", "methodName" => "main"})

    Log.trace(instance.factorial(5), %{"fileName" => "Main.hx", "lineNumber" => 80, "className" => "Main", "methodName" => "main"})

    Log.trace(instance.day_name(3), %{"fileName" => "Main.hx", "lineNumber" => 81, "className" => "Main", "methodName" => "main"})
  end

  # Instance functions
  @doc "Generated from Haxe calculate"
  def calculate(%__MODULE__{} = struct, x, y) do
    (x + (y * struct.instance_var))
  end

  @doc "Generated from Haxe checkValue"
  def check_value(%__MODULE__{} = struct, n) do
    if ((n < 0)) do
      "negative"
    else
      if ((n == 0)) do
        "zero"
      else
        "positive"
      end
    end
  end

  @doc "Generated from Haxe sumRange"
  def sum_range(%__MODULE__{} = struct, start, end_) do
    sum = 0

    g_array = start

    g_array = end_

    (fn loop ->
      if ((g_array < g_array)) do
            i = g_array + 1
        sum = sum + i
        loop.()
      end
    end).()

    sum
  end

  @doc "Generated from Haxe factorial"
  def factorial(%__MODULE__{} = struct, n) do
    result = 1

    i = n

    (fn loop ->
      if ((i > 1)) do
            result = result * i
        i - 1
        loop.()
      end
    end).()

    result
  end

  @doc "Generated from Haxe dayName"
  def day_name(%__MODULE__{} = struct, day) do
    temp_result = nil

    temp_result = nil

    case day do
      1 -> "Monday"
      2 -> "Tuesday"
      3 -> "Wednesday"
      4 -> "Thursday"
      5 -> "Friday"
      6 -> "Saturday"
      7 -> "Sunday"
      _ -> "Invalid"
    end

    temp_result
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
