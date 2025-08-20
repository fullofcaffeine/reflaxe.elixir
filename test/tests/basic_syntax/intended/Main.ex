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
  @doc "Function greet"
  @spec greet(String.t()) :: String.t()
  def greet(name) do
    "Hello, " <> name <> "!"
  end

  @doc "Function main"
  @spec main() :: nil
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
  @doc "Function calculate"
  @spec calculate(t(), integer(), integer()) :: integer()
  def calculate(%__MODULE__{} = struct, x, y) do
    x + y * struct.instance_var
  end

  @doc "Function check_value"
  @spec check_value(t(), integer()) :: String.t()
  def check_value(%__MODULE__{} = struct, n) do
    if (n < 0), do: "negative", else: if (n == 0), do: "zero", else: "positive"
  end

  @doc "Function sum_range"
  @spec sum_range(t(), integer(), integer()) :: integer()
  def sum_range(%__MODULE__{} = struct, start, end_) do
    sum = 0
    _g_1 = start
    _g_2 = end_
    (
      loop_helper = fn loop_fn, {sum} ->
        if (g < g) do
          try do
            i = g = g + 1
    sum = sum + i
            loop_fn.(loop_fn, {sum})
          catch
            :break -> {sum}
            :continue -> loop_fn.(loop_fn, {sum})
          end
        else
          {sum}
        end
      end
      {sum} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    sum
  end

  @doc "Function factorial"
  @spec factorial(t(), integer()) :: integer()
  def factorial(%__MODULE__{} = struct, n) do
    result = 1
    i = n
    (
      loop_helper = fn loop_fn, {result, i} ->
        if (i > 1) do
          try do
            result = result * i
          i = i - 1
          loop_fn.({result * i, i - 1})
            loop_fn.(loop_fn, {result, i})
          catch
            :break -> {result, i}
            :continue -> loop_fn.(loop_fn, {result, i})
          end
        else
          {result, i}
        end
      end
      {result, i} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
    result
  end

  @doc "Function day_name"
  @spec day_name(t(), integer()) :: String.t()
  def day_name(%__MODULE__{} = struct, day) do
    temp_result = nil
    case (day) do
      1 ->
        temp_result = "Monday"
      2 ->
        temp_result = "Tuesday"
      3 ->
        temp_result = "Wednesday"
      4 ->
        temp_result = "Thursday"
      5 ->
        temp_result = "Friday"
      6 ->
        temp_result = "Saturday"
      7 ->
        temp_result = "Sunday"
      _ ->
        temp_result = "Invalid"
    end
    temp_result
  end

end
