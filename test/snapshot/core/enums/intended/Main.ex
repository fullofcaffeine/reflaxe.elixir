defmodule Main do
  def color_to_string(color) do
    ___elixir_switch_result_1 = case (color) do
  0 ->
    "red"
  1 ->
    "green"
  2 ->
    "blue"
  3 ->
    _r = elem(color, 1)
    _b = elem(color, 3)
    "rgb(#{r}, #{_g1}, #{b})"
end
    __elixir_switch_result_1
  end
  def get_value(opt, default_value) do
    ___elixir_switch_result_2 = case (opt) do
  0 ->
    _v = elem(opt, 1)
    v
  1 ->
    default_value
end
    __elixir_switch_result_2
  end
  def tree_sum(tree) do
    ___elixir_switch_result_3 = case (tree) do
  0 ->
    _value = elem(tree, 1)
    value
  1 ->
    _left = elem(tree, 1)
    _right = elem(tree, 2)
    Main.treeSum(left) + Main.treeSum(right)
end
    __elixir_switch_result_3
  end
  def describe_rgb(color) do
    case color do
      {:rgb, _, _, _} ->
        nil
        nil
        nil
        nil
        if (r > 200 and g < 50 and b < 50) do
          "mostly red"
        else
          _r2 = g
          _b2 = g2
          if (g1 > 200 and r2 < 50 and b2 < 50) do
            "mostly green"
          else
            _r3 = g
            _b3 = g2
            if (b3 > 200 and r3 < 50 and g1 < 50) do
              "mostly blue"
            else
              _r4 = g
              _b4 = g2
              "mixed color"
            end
          end
        end
      _ ->
        "not RGB"
    end
  end
  def compare_trees(t1, t2) do
    ___elixir_switch_result_4 = case (t1) do
  0 ->
    case t2 do
      {:leaf, _} ->
        _v2 = elem(t2, 1)
        _v1 = elem(t1, 1)
        v1 == v2
      _ ->
        false
    end
  1 ->
    case t2 do
      {:node, _, _} ->
        _l2 = elem(t2, 1)
        _r2 = elem(t2, 2)
        _r1 = elem(t1, 2)
        _l1 = elem(t1, 1)
        Main.compareTrees(l1, l2) and Main.compareTrees(r1, r2)
      _ ->
        false
    end
end
    __elixir_switch_result_4
  end
  def main() do
    _color = {:rgb, 255, 128, 0}
    Log.trace(Main.colorToString(color), %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "main"})
    _some = {:some, "Hello"}
    _none = :none
    Log.trace(Main.getValue(some, "default"), %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "main"})
    Log.trace(Main.getValue(none, "default"), %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "main"})
    _tree = {:node, {:leaf, 1}, {:node, {:leaf, 2}, {:leaf, 3}}}
    Log.trace(Main.treeSum(tree), %{:file_name => "Main.hx", :line_number => 92, :class_name => "Main", :method_name => "main"})
    Log.trace(Main.describeRGB({:rgb, 250, 10, 10}), %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "main"})
    _tree2 = {:node, {:leaf, 1}, {:node, {:leaf, 2}, {:leaf, 3}}}
    Log.trace(Main.compareTrees(tree, tree2), %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "main"})
  end
end