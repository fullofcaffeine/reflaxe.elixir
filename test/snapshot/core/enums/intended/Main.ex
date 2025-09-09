defmodule Main do
  def color_to_string(_color) do
    case (elem(_color, 0)) do
      0 ->
        "red"
      1 ->
        "green"
      2 ->
        "blue"
      3 ->
        g = elem(_color, 1)
        g1 = elem(_color, 2)
        g2 = elem(_color, 3)
        r = g
        g = g1
        b = g2
        "rgb(" <> Kernel.to_string(r) <> ", " <> Kernel.to_string(g) <> ", " <> Kernel.to_string(b) <> ")"
    end
  end
  def get_value(_opt, default_value) do
    case (elem(_opt, 0)) do
      0 ->
        g = elem(_opt, 1)
        v = g
        v
      1 ->
        default_value
    end
  end
  def tree_sum(_tree) do
    case (elem(_tree, 0)) do
      0 ->
        g = elem(_tree, 1)
        value = g
        value
      1 ->
        g = elem(_tree, 1)
        g1 = elem(_tree, 2)
        left = g
        right = g1
        tree_sum(left) + tree_sum(right)
    end
  end
  def describe_rgb(_color) do
    if (elem(_color, 0) == 3) do
      g = elem(_color, 1)
      g1 = elem(_color, 2)
      g2 = elem(_color, 3)
      r = g
      g = g1
      b = g2
      if (r > 200 && g < 50 && b < 50) do
        "mostly red"
      else
        r = g
        g = g1
        b = g2
        if (g > 200 && r < 50 && b < 50) do
          "mostly green"
        else
          r = g
          g = g1
          b = g2
          if (b > 200 && r < 50 && g < 50) do
            "mostly blue"
          else
            _r = g
            _g = g1
            _b = g2
            "mixed color"
          end
        end
      end
    else
      "not RGB"
    end
  end
  def compare_trees(_t1, _t2) do
    case (elem(_t1, 0)) do
      0 ->
        g = elem(_t1, 1)
        if (elem(_t2, 0) == 0) do
          g1 = elem(_t2, 1)
          v2 = g1
          v1 = g
          v1 == v2
        else
          false
        end
      1 ->
        g = elem(_t1, 1)
        g1 = elem(_t1, 2)
        if (elem(_t2, 0) == 1) do
          g2 = elem(_t2, 1)
          g3 = elem(_t2, 2)
          l2 = g2
          r2 = g3
          r1 = g1
          l1 = g
          compare_trees(l1, l2) && compare_trees(r1, r2)
        else
          false
        end
    end
  end
  def main() do
    color = {:RGB, 255, 128, 0}
    Log.trace(color_to_string(color), %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "main"})
    some = {:Some, "Hello"}
    none = {1}
    Log.trace(get_value(some, "default"), %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "main"})
    Log.trace(get_value(none, "default"), %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "main"})
    tree = {:Node, {:Leaf, 1}, {:Node, {:Leaf, 2}, {:Leaf, 3}}}
    Log.trace(tree_sum(tree), %{:file_name => "Main.hx", :line_number => 92, :class_name => "Main", :method_name => "main"})
    Log.trace(describe_r_g_b({:RGB, 250, 10, 10}), %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "main"})
    tree2 = {:Node, {:Leaf, 1}, {:Node, {:Leaf, 2}, {:Leaf, 3}}}
    Log.trace(compare_trees(tree, tree2), %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()