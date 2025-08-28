defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Generated from Haxe colorToString"
  def color_to_string(color) do
    temp_result = nil

    temp_result = nil

    case color do
      0 -> temp_result = "red"
      1 -> temp_result = "green"
      2 -> temp_result = "blue"
      3 -> g_param_0 = elem(color, 1)
    g_param_1 = elem(color, 2)
    g_param_2 = elem(color, 3)
    r = g_param_2
    g_array = g_array
    b = g_param_2
    temp_result = "rgb(" <> to_string(r) <> ", " <> to_string(g_array) <> ", " <> to_string(b) <> ")"
    end

    temp_result
  end

  @doc "Generated from Haxe getValue"
  def get_value(opt, default_value) do
    temp_result = nil

    case opt do
      0 -> v = elem(opt, 1)
    temp_result = v
      1 -> temp_result = default_value
    end

    temp_result
  end

  @doc "Generated from Haxe treeSum"
  def tree_sum(tree) do
    temp_result = nil

    case tree do
      0 -> value = elem(tree, 1)
    temp_result = value
      1 -> g_param_0 = elem(tree, 1)
    g_param_1 = elem(tree, 2)
    left = g_param_1
    right = g_param_1
    temp_result = (Main.tree_sum(left) + Main.tree_sum(right))
    end

    temp_result
  end

  @doc "Generated from Haxe describeRGB"
  def describe_r_g_b(color) do
    temp_result = nil

    if ((case color do :red -> 0; :green -> 1; :blue -> 2; :r_g_b -> 3; _ -> -1 end == 3)) do
      g_param_0 = elem(color, 1)
      g_param_1 = elem(color, 2)
      g_param_2 = elem(color, 3)
      r = g_param_2
      g_array = g_array
      b = g_param_2
      if ((((r > 200) && (g_array < 50)) && (b < 50))) do
        temp_result = "mostly red"
      else
        r = g_param_2
        g_array = g_array
        b = g_param_2
        if ((((g_array > 200) && (r < 50)) && (b < 50))) do
          temp_result = "mostly green"
        else
          r = g_param_2
          g_array = g_array
          b = g_param_2
          if ((((b > 200) && (r < 50)) && (g_array < 50))) do
            temp_result = "mostly blue"
          else
            _r = g_param_2
            g_array = g_array
            _b = g_param_2
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
  def compare_trees(t1, t2) do
    temp_result = nil

    case t1 do
      0 -> g_param_0 = elem(t1, 1)
    if ((case t2 do :leaf -> 0; :node_ -> 1; _ -> -1 end == 0)) do
      g_param_0 = elem(t2, 1)
      v2 = g_param_0
      v1 = g_param_0
      temp_result = (v1 == v2)
    else
      temp_result = false
    end
      1 -> g_param_0 = elem(t1, 1)
    g_param_1 = elem(t1, 2)
    if ((case t2 do :leaf -> 0; :node_ -> 1; _ -> -1 end == 1)) do
      g_param_0 = elem(t2, 1)
      g_param_1 = elem(t2, 2)
      l2 = g_param_1
      r2 = g_param_1
      r1 = g_param_1
      l1 = g_param_1
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
