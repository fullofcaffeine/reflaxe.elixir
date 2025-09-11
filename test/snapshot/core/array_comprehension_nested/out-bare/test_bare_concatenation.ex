defmodule TestBareConcatenation do
  def main() do
    g = []
    g = g ++ [g = []
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g]
    g = g ++ [g = []
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g]
    deeply_nested = g
g
    Log.trace("Deeply nested with bare concatenations:", %{:file_name => "TestBareConcatenation.hx", :line_number => 19, :class_name => "TestBareConcatenation", :method_name => "main"})
    Log.trace(deeply_nested, %{:file_name => "TestBareConcatenation.hx", :line_number => 20, :class_name => "TestBareConcatenation", :method_name => "main"})
    g = []
    g = g ++ [g = []
g ++ [g = []
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g]
g ++ [g = []
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g]
g]
    g = g ++ [g = []
g ++ [g = []
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g]
g ++ [g = []
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g ++ [g = []
g ++ [0]
g ++ [1]
g]
g]
g]
    very_deep = g
g
    Log.trace("Very deep nesting:", %{:file_name => "TestBareConcatenation.hx", :line_number => 28, :class_name => "TestBareConcatenation", :method_name => "main"})
    Log.trace(very_deep, %{:file_name => "TestBareConcatenation.hx", :line_number => 29, :class_name => "TestBareConcatenation", :method_name => "main"})
    n = 2
    g = []
    g = g ++ [g = []
g1 = 0
g2 = n
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g2, :ok}, fn _, {acc_g1, acc_g2, acc_state} ->
  if (acc_g1 < acc_g2) do
    g ++ [(acc_g1 = acc_g1 + 1)]
    {:cont, {acc_g1, acc_g2, acc_state}}
  else
    {:halt, {acc_g1, acc_g2, acc_state}}
  end
end)
g]
    g = g ++ [g = []
g1 = 0
g2 = n
Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g1, g2, :ok}, fn _, {acc_g1, acc_g2, acc_state} ->
  if (acc_g1 < acc_g2) do
    g ++ [(acc_g1 = acc_g1 + 1)]
    {:cont, {acc_g1, acc_g2, acc_state}}
  else
    {:halt, {acc_g1, acc_g2, acc_state}}
  end
end)
g]
    mixed = g
g
    Log.trace("Mixed constant/variable:", %{:file_name => "TestBareConcatenation.hx", :line_number => 36, :class_name => "TestBareConcatenation", :method_name => "main"})
    Log.trace(mixed, %{:file_name => "TestBareConcatenation.hx", :line_number => 37, :class_name => "TestBareConcatenation", :method_name => "main"})
  end
end