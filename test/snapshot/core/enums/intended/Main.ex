defmodule Main do
  def color_to_string(color) do
    case (color.elem(0)) do
      0 ->
        "red"
      1 ->
        "green"
      2 ->
        "blue"
      3 ->
        g = color.elem(1)
        g1 = color.elem(2)
        g2 = color.elem(3)
        r = g
        g = g1
        b = g2
        "rgb(" + r + ", " + g + ", " + b + ")"
    end
  end
  def get_value(opt, default_value) do
    case (opt.elem(0)) do
      0 ->
        g = opt.elem(1)
        v = g
        v
      1 ->
        default_value
    end
  end
  def tree_sum(tree) do
    case (tree.elem(0)) do
      0 ->
        g = tree.elem(1)
        value = g
        value
      1 ->
        g = tree.elem(1)
        g1 = tree.elem(2)
        left = g
        right = g1
        Main.tree_sum(left) + Main.tree_sum(right)
    end
  end
  def describe_rgb(color) do
    if (color.elem(0) == 3) do
      g = color.elem(1)
      g1 = color.elem(2)
      g2 = color.elem(3)
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
            r = g
            g = g1
            b = g2
            "mixed color"
          end
        end
      end
    else
      "not RGB"
    end
  end
  def compare_trees(t1, t2) do
    case (t1.elem(0)) do
      0 ->
        g = t1.elem(1)
        if (t2.elem(0) == 0) do
          g1 = t2.elem(1)
          v_2 = g1
          v_1 = g
          v == v
        else
          false
        end
      1 ->
        g = t1.elem(1)
        g1 = t1.elem(2)
        if (t2.elem(0) == 1) do
          g2 = t2.elem(1)
          g3 = t2.elem(2)
          l_2 = g2
          r_2 = g3
          r_1 = g1
          l_1 = g
          Main.compare_trees(l, l) && Main.compare_trees(r, r)
        else
          false
        end
    end
  end
  def main() do
    color = {:RGB, 255, 128, 0}
    Log.trace(Main.color_to_string(color), %{:fileName => "Main.hx", :lineNumber => 79, :className => "Main", :methodName => "main"})
    some = {:Some, "Hello"}
    none = :None
    Log.trace(Main.get_value(some, "default"), %{:fileName => "Main.hx", :lineNumber => 84, :className => "Main", :methodName => "main"})
    Log.trace(Main.get_value(none, "default"), %{:fileName => "Main.hx", :lineNumber => 85, :className => "Main", :methodName => "main"})
    tree = {:Node, {:Leaf, 1}, {:Node, {:Leaf, 2}, {:Leaf, 3}}}
    Log.trace(Main.tree_sum(tree), %{:fileName => "Main.hx", :lineNumber => 92, :className => "Main", :methodName => "main"})
    Log.trace(Main.describe_r_g_b({:RGB, 250, 10, 10}), %{:fileName => "Main.hx", :lineNumber => 95, :className => "Main", :methodName => "main"})
    tree_2 = {:Node, {:Leaf, 1}, {:Node, {:Leaf, 2}, {:Leaf, 3}}}
    Log.trace(Main.compare_trees(tree, tree), %{:fileName => "Main.hx", :lineNumber => 99, :className => "Main", :methodName => "main"})
  end
end