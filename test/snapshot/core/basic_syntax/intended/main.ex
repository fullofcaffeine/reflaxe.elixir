defmodule Main do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Main, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Main, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def constant() do
    __haxe_static_get__(:constant, 42)
  end
  def constant(value) do
    __haxe_static_put__(:constant, value)
  end
  def static_var() do
    __haxe_static_get__(:static_var, "hello")
  end
  def static_var(value) do
    __haxe_static_put__(:static_var, value)
  end
  def new(value) do
    struct = %{:instance_var => nil}
    struct = %{struct | instance_var: value}
    struct
  end
  def calculate(struct, x, y) do
    x + y * struct.instance_var
  end
  def check_value(_, n) do
    cond do
      n < 0 -> "negative"
      n == 0 -> "zero"
      :true -> "positive"
    end
  end
  def sum_range(_, start, end_param) do
    sum = 0
    _g = start
    g_value = end_param
    sum = Enum.reduce(0..(g_value - 1)//1, sum, fn i, sum_acc -> sum_acc + i end)
    sum
  end
  def factorial(_, n) do
    result = 1
    i = n
    {result, _i} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, i}, fn _, {acc_result, acc_i} ->
      try do
        if (acc_i > 1) do
          acc_result = acc_result * acc_i
          old_i = acc_i
          acc_i = (acc_i - 1)
          {:cont, {acc_result, acc_i}}
        else
          {:halt, {acc_result, acc_i}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_result, acc_i}}
        :throw, :continue ->
          {:cont, {acc_result, acc_i}}
      end
    end)
    result
  end
  def day_name(_, day) do
    (case day do
      1 -> "Monday"
      2 -> "Tuesday"
      3 -> "Wednesday"
      4 -> "Thursday"
      5 -> "Friday"
      6 -> "Saturday"
      7 -> "Sunday"
      _ -> "Invalid"
    end)
  end
  def greet(name) do
    "Hello, #{(fn -> name end).()}!"
  end
  def main() do
    _instance = Main.new(10)
    nil
  end
end
