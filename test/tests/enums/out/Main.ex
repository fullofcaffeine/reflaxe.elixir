defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  """

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
    color = Color.RGB(255, 128, 0)
    Log.trace(Main.colorToString(color), %{fileName => "Main.hx", lineNumber => 79, className => "Main", methodName => "main"})
    some = {:some, "Hello"}
    none = :none
    Log.trace(Main.getValue(some, "default"), %{fileName => "Main.hx", lineNumber => 84, className => "Main", methodName => "main"})
    Log.trace(Main.getValue(none, "default"), %{fileName => "Main.hx", lineNumber => 85, className => "Main", methodName => "main"})
    tree = Tree.Node(Tree.Leaf(1), Tree.Node(Tree.Leaf(2), Tree.Leaf(3)))
    Log.trace(Main.treeSum(tree), %{fileName => "Main.hx", lineNumber => 92, className => "Main", methodName => "main"})
    Log.trace(Main.describeRGB(Color.RGB(250, 10, 10)), %{fileName => "Main.hx", lineNumber => 95, className => "Main", methodName => "main"})
    tree2 = Tree.Node(Tree.Leaf(1), Tree.Node(Tree.Leaf(2), Tree.Leaf(3)))
    Log.trace(Main.compareTrees(tree, tree2), %{fileName => "Main.hx", lineNumber => 99, className => "Main", methodName => "main"})
  end

end


defmodule Color do
  @moduledoc """
  Color enum generated from Haxe
  
  
 * Enum test case
 * Tests enum compilation and pattern matching
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :red |
    :green |
    :blue |
    {:r_g_b, term(), term(), term()}

  @doc "Creates red enum value"
  @spec red() :: :red
  def red(), do: :red

  @doc "Creates green enum value"
  @spec green() :: :green
  def green(), do: :green

  @doc "Creates blue enum value"
  @spec blue() :: :blue
  def blue(), do: :blue

  @doc """
  Creates r_g_b enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec r_g_b(term(), term(), term()) :: {:r_g_b, term(), term(), term()}
  def r_g_b(arg0, arg1, arg2) do
    {:r_g_b, arg0, arg1, arg2}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is red variant"
  @spec is_red(t()) :: boolean()
  def is_red(:red), do: true
  def is_red(_), do: false

  @doc "Returns true if value is green variant"
  @spec is_green(t()) :: boolean()
  def is_green(:green), do: true
  def is_green(_), do: false

  @doc "Returns true if value is blue variant"
  @spec is_blue(t()) :: boolean()
  def is_blue(:blue), do: true
  def is_blue(_), do: false

  @doc "Returns true if value is r_g_b variant"
  @spec is_r_g_b(t()) :: boolean()
  def is_r_g_b({:r_g_b, _}), do: true
  def is_r_g_b(_), do: false

  @doc "Extracts value from r_g_b variant, returns {:ok, value} or :error"
  @spec get_r_g_b_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_r_g_b_value({:r_g_b, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_r_g_b_value(_), do: :error

end


defmodule Option do
  @moduledoc """
  Option enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:some, term()} |
    :none

  @doc """
  Creates some enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec some(term()) :: {:some, term()}
  def some(arg0) do
    {:some, arg0}
  end

  @doc "Creates none enum value"
  @spec none() :: :none
  def none(), do: :none

  # Predicate functions for pattern matching
  @doc "Returns true if value is some variant"
  @spec is_some(t()) :: boolean()
  def is_some({:some, _}), do: true
  def is_some(_), do: false

  @doc "Returns true if value is none variant"
  @spec is_none(t()) :: boolean()
  def is_none(:none), do: true
  def is_none(_), do: false

  @doc "Extracts value from some variant, returns {:ok, value} or :error"
  @spec get_some_value(t()) :: {:ok, term()} | :error
  def get_some_value({:some, value}), do: {:ok, value}
  def get_some_value(_), do: :error

end


defmodule Tree do
  @moduledoc """
  Tree enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:leaf, term()} |
    {:node_, term(), term()}

  @doc """
  Creates leaf enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec leaf(term()) :: {:leaf, term()}
  def leaf(arg0) do
    {:leaf, arg0}
  end

  @doc """
  Creates node_ enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec node_(term(), term()) :: {:node_, term(), term()}
  def node_(arg0, arg1) do
    {:node_, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is leaf variant"
  @spec is_leaf(t()) :: boolean()
  def is_leaf({:leaf, _}), do: true
  def is_leaf(_), do: false

  @doc "Returns true if value is node_ variant"
  @spec is_node_(t()) :: boolean()
  def is_node_({:node_, _}), do: true
  def is_node_(_), do: false

  @doc "Extracts value from leaf variant, returns {:ok, value} or :error"
  @spec get_leaf_value(t()) :: {:ok, term()} | :error
  def get_leaf_value({:leaf, value}), do: {:ok, value}
  def get_leaf_value(_), do: :error

  @doc "Extracts value from node_ variant, returns {:ok, value} or :error"
  @spec get_node__value(t()) :: {:ok, {term(), term()}} | :error
  def get_node__value({:node_, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_node__value(_), do: :error

end
