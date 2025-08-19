defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Function color_to_string"
  @spec color_to_string(Color.t()) :: String.t()
  def color_to_string(color) do
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
        temp_result = "rgb(" <> Integer.to_string(r) <> ", " <> Integer.to_string(g) <> ", " <> Integer.to_string(b) <> ")"
    end
    temp_result
  end

  @doc "Function get_value"
  @spec get_value(Option.t(), T.t()) :: T.t()
  def get_value(opt, default_value) do
    temp_result = nil
    case (elem(opt, 0)) do
      0 ->
        _g = elem(opt, 1)
        v = _g
        temp_result = v
      1 ->
        temp_result = default_value
    end
    temp_result
  end

  @doc "Function tree_sum"
  @spec tree_sum(Tree.t()) :: integer()
  def tree_sum(tree) do
    temp_result = nil
    case (elem(tree, 0)) do
      0 ->
        _g = elem(tree, 1)
        value = _g
        temp_result = value
      1 ->
        _g = elem(tree, 1)
        _g = elem(tree, 2)
        left = _g
        right = _g
        temp_result = Main.treeSum(left) + Main.treeSum(right)
    end
    temp_result
  end

  @doc "Function describe_r_g_b"
  @spec describe_r_g_b(Color.t()) :: String.t()
  def describe_r_g_b(color) do
    temp_result = nil
    if (elem(color, 0) == 3) do
      _g = elem(color, 1)
      _g = elem(color, 2)
      _g = elem(color, 3)
      r = _g
      g = _g
      b = _g
      if (r > 200 && g < 50 && b < 50) do
        temp_result = "mostly red"
      else
        r = _g
        g = _g
        b = _g
        if (g > 200 && r < 50 && b < 50) do
          temp_result = "mostly green"
        else
          r = _g
          g = _g
          b = _g
          if (b > 200 && r < 50 && g < 50) do
            temp_result = "mostly blue"
          else
            _g
            _g
            _g
            temp_result = "mixed color"
          end
        end
      end
    else
      temp_result = "not RGB"
    end
    temp_result
  end

  @doc "Function compare_trees"
  @spec compare_trees(Tree.t(), Tree.t()) :: boolean()
  def compare_trees(t1, t2) do
    temp_result = nil
    case (elem(t1, 0)) do
      0 ->
        _g = elem(t1, 1)
        if (elem(t2, 0) == 0) do
          _g = elem(t2, 1)
          v2 = _g
          v1 = _g
          temp_result = v1 == v2
        else
          temp_result = false
        end
      1 ->
        _g = elem(t1, 1)
        _g = elem(t1, 2)
        if (elem(t2, 0) == 1) do
          _g = elem(t2, 1)
          _g = elem(t2, 2)
          l2 = _g
          r2 = _g
          r1 = _g
          l1 = _g
          temp_result = Main.compareTrees(l1, l2) && Main.compareTrees(r1, r2)
        else
          temp_result = false
        end
    end
    temp_result
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    color = {:r_g_b, 255, 128, 0}
    Log.trace(Main.colorToString(color), %{"fileName" => "Main.hx", "lineNumber" => 79, "className" => "Main", "methodName" => "main"})
    some = {:some, "Hello"}
    none = :none
    Log.trace(Main.getValue(some, "default"), %{"fileName" => "Main.hx", "lineNumber" => 84, "className" => "Main", "methodName" => "main"})
    Log.trace(Main.getValue(none, "default"), %{"fileName" => "Main.hx", "lineNumber" => 85, "className" => "Main", "methodName" => "main"})
    tree = {:node_, {:leaf, 1}, {:node_, {:leaf, 2}, {:leaf, 3}}}
    Log.trace(Main.treeSum(tree), %{"fileName" => "Main.hx", "lineNumber" => 92, "className" => "Main", "methodName" => "main"})
    Log.trace(Main.describeRGB({:r_g_b, 250, 10, 10}), %{"fileName" => "Main.hx", "lineNumber" => 95, "className" => "Main", "methodName" => "main"})
    tree2 = {:node_, {:leaf, 1}, {:node_, {:leaf, 2}, {:leaf, 3}}}
    Log.trace(Main.compareTrees(tree, tree2), %{"fileName" => "Main.hx", "lineNumber" => 99, "className" => "Main", "methodName" => "main"})
  end

end
