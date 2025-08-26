defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe colorToString"
  def color_to_string(_color) do
    temp_result = nil

    temp_result = nil

    case (case color do :red -> 0; :green -> 1; :blue -> 2; :r_g_b -> 3; _ -> -1 end) do
      0 -> temp_result = "red"
      1 -> temp_result = "green"
      2 -> temp_result = "blue"
      {3, r, g, b} -> g_array = elem(color, 1)
    g_array = elem(color, 2)
    g_array = elem(color, 3)
    temp_result = "rgb(" <> to_string(r) <> ", " <> to_string(g_array) <> ", " <> to_string(b) <> ")"
    end

    temp_result
  end

  @doc "Generated from Haxe getValue"
  def get_value(_opt, default_value) do
    temp_result = nil

    case (case opt do :some -> 0; :none -> 1; _ -> -1 end) do
      {0, v} -> g_array = elem(opt, 1)
    temp_result = v
      1 -> temp_result = default_value
    end

    temp_result
  end

  @doc "Generated from Haxe treeSum"
  def tree_sum(_tree) do
    temp_result = nil

    case (case tree do :leaf -> 0; :node_ -> 1; _ -> -1 end) do
      {0, value} -> g_array = elem(tree, 1)
    temp_result = value
      {1, left, right} -> g_array = elem(tree, 1)
    g_array = elem(tree, 2)
    temp_result = (Main.tree_sum(left) + Main.tree_sum(right))
    end

    temp_result
  end

  @doc "Generated from Haxe describeRGB"
  def describe_r_g_b(_color) do
    temp_result = nil

    if ((case color do :red -> 0; :green -> 1; :blue -> 2; :r_g_b -> 3; _ -> -1 end == 3)) do
      g_array = elem(color, 1)
      g_array = elem(color, 2)
      g_array = elem(color, 3)
      r = g_array
      g_array = g_array
      b = g_array
      if ((((r > 200) && (g_array < 50)) && (b < 50))) do
        temp_result = "mostly red"
      else
        r = g_array
        g_array = g_array
        b = g_array
        if ((((g_array > 200) && (r < 50)) && (b < 50))) do
          temp_result = "mostly green"
        else
          r = g_array
          g_array = g_array
          b = g_array
          if ((((b > 200) && (r < 50)) && (g_array < 50))) do
            temp_result = "mostly blue"
          else
            _r = g_array
            g_array = g_array
            _b = g_array
            temp_result = "mixed color"
          end
        end
      end
    else
      temp_result = "not RGB"
    end

    temp_result
  end

  @doc "Generated from Haxe compareTrees"
  def compare_trees(_t1, _t2) do
    temp_result = nil

    case (case t1 do :leaf -> 0; :node_ -> 1; _ -> -1 end) do
      {0, v} -> g_array = elem(t1, 1)
    if ((case t2 do :leaf -> 0; :node_ -> 1; _ -> -1 end == 0)) do
      temp_result = (v1 == v2)
    else
      temp_result = false
    end
      {1, l, r} -> g_array = elem(t1, 1)
    g_array = elem(t1, 2)
    if ((case t2 do :leaf -> 0; :node_ -> 1; _ -> -1 end == 1)) do
      temp_result = (Main.compare_trees(l1, l2) && Main.compare_trees(r1, r2))
    else
      temp_result = false
    end
    end

    temp_result
  end

  @doc "Generated from Haxe main"
  def main() do
    color = Color.r_g_b(255, 128, 0)

    Log.trace(Main.color_to_string(color), %{"fileName" => "Main.hx", "lineNumber" => 79, "className" => "Main", "methodName" => "main"})

    some = Option.some("Hello")

    none = :none

    Log.trace(Main.get_value(some, "default"), %{"fileName" => "Main.hx", "lineNumber" => 84, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.get_value(none, "default"), %{"fileName" => "Main.hx", "lineNumber" => 85, "className" => "Main", "methodName" => "main"})

    tree = Tree.node_(Tree.leaf(1), Tree.node_(Tree.leaf(2), Tree.leaf(3)))

    Log.trace(Main.tree_sum(tree), %{"fileName" => "Main.hx", "lineNumber" => 92, "className" => "Main", "methodName" => "main"})

    Log.trace(Main.describe_r_g_b(Color.r_g_b(250, 10, 10)), %{"fileName" => "Main.hx", "lineNumber" => 95, "className" => "Main", "methodName" => "main"})

    tree2 = Tree.node_(Tree.leaf(1), Tree.node_(Tree.leaf(2), Tree.leaf(3)))

    Log.trace(Main.compare_trees(tree, tree2), %{"fileName" => "Main.hx", "lineNumber" => 99, "className" => "Main", "methodName" => "main"})
  end

end
