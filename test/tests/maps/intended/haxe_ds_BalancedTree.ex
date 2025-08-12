defmodule BalancedTree do
  @moduledoc """
  BalancedTree module generated from Haxe
  
  
	BalancedTree allows key-value mapping with arbitrary keys, as long as they
	can be ordered. By default, `Reflect.compare` is used in the `compare`
	method, which can be overridden in subclasses.

	Operations have a logarithmic average and worst-case cost.

	Iteration over keys and values, using `keys` and `iterator` respectively,
	are in-order.

  """

  # Instance functions
  @doc "
		Binds `key` to `value`.

		If `key` is already bound to a value, that binding disappears.

		If `key` is null, the result is unspecified.
	"
  @spec set(TInst(haxe.Ds.BalancedTree.K,[]).t(), TInst(haxe.Ds.BalancedTree.V,[]).t()) :: TAbstract(Void,[]).t()
  def set(arg0, arg1) do
    self().root = self().setLoop(key, value, self().root)
  end

  @doc "
		Returns the value `key` is bound to.

		If `key` is not bound to any value, `null` is returned.

		If `key` is null, the result is unspecified.
	"
  @spec get(TInst(haxe.Ds.BalancedTree.K,[]).t()) :: TAbstract(Null,[TInst(haxe.Ds.BalancedTree.V,[])]).t()
  def get(arg0) do
    (
  node = self().root
  while (node != nil) do
  (
  c = self().compare(key, node.key)
  if (c == 0), do: node.value, else: nil
  if (c < 0), do: node = node.left, else: node = node.right
)
end
  nil
)
  end

  @doc "
		Tells if `key` is bound to a value.

		This method returns true even if `key` is bound to null.

		If `key` is null, the result is unspecified.
	"
  @spec exists(TInst(haxe.Ds.BalancedTree.K,[]).t()) :: TAbstract(Bool,[]).t()
  def exists(arg0) do
    (
  node = self().root
  while (node != nil) do
  (
  c = self().compare(key, node.key)
  if (c == 0), do: true, else: if (c < 0), do: node = node.left, else: node = node.right
)
end
  false
)
  end

  @doc "
		Iterates over the keys of `this` BalancedTree.

		This operation is performed in-order.
	"
  @spec keys() :: TType(Iterator,[TInst(haxe.Ds.BalancedTree.K,[])]).t()
  def keys() do
    (
  ret = []
  self().keysLoop(self().root, ret)
  Haxe.Iterators.ArrayIterator.new(ret)
)
  end

  @doc "Function set_loop"
  @spec set_loop(TInst(haxe.Ds.BalancedTree.K,[]).t(), TInst(haxe.Ds.BalancedTree.V,[]).t(), TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t()) :: TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t()
  def set_loop(arg0, arg1, arg2) do
    (
  if (node == nil), do: Haxe.Ds.TreeNode.new(nil, k, v, nil), else: nil
  c = self().compare(k, node.key)
  temp_result = nil
  if (c == 0), do: (
  temp_number = nil
  if (node == nil), do: temp_number = 0, else: temp_number = node._height
  temp_result = Haxe.Ds.TreeNode.new(node.left, k, v, node.right, temp_number)
), else: if (c < 0), do: (
  nl = self().setLoop(k, v, node.left)
  temp_result = self().balance(nl, node.key, node.value, node.right)
), else: (
  nr = self().setLoop(k, v, node.right)
  temp_result = self().balance(node.left, node.key, node.value, nr)
)
  temp_result
)
  end

  @doc "Function keys_loop"
  @spec keys_loop(TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t(), TInst(Array,[TInst(haxe.Ds.BalancedTree.K,[])]).t()) :: TAbstract(Void,[]).t()
  def keys_loop(arg0, arg1) do
    if (node != nil), do: (
  self().keysLoop(node.left, acc)
  acc.push(node.key)
  self().keysLoop(node.right, acc)
), else: nil
  end

  @doc "Function balance"
  @spec balance(TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t(), TInst(haxe.Ds.BalancedTree.K,[]).t(), TInst(haxe.Ds.BalancedTree.V,[]).t(), TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t()) :: TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t()
  def balance(arg0, arg1, arg2, arg3) do
    (
  temp_number = nil
  if (l == nil), do: temp_number = 0, else: temp_number = l._height
  hl = temp_number
  temp_number1 = nil
  if (r == nil), do: temp_number1 = 0, else: temp_number1 = r._height
  hr = temp_number1
  temp_result = nil
  if (hl > hr + 2), do: (
  temp_left = nil
  (
  _this = l.left
  if (_this == nil), do: temp_left = 0, else: temp_left = _this._height
)
  temp_right = nil
  (
  _this = l.right
  if (_this == nil), do: temp_right = 0, else: temp_right = _this._height
)
  if (temp_left >= temp_right), do: temp_result = Haxe.Ds.TreeNode.new(l.left, l.key, l.value, Haxe.Ds.TreeNode.new(l.right, k, v, r)), else: temp_result = Haxe.Ds.TreeNode.new(Haxe.Ds.TreeNode.new(l.left, l.key, l.value, l.right.left), l.right.key, l.right.value, Haxe.Ds.TreeNode.new(l.right.right, k, v, r))
), else: if (hr > hl + 2), do: (
  temp_left1 = nil
  (
  _this = r.right
  if (_this == nil), do: temp_left1 = 0, else: temp_left1 = _this._height
)
  temp_right1 = nil
  (
  _this = r.left
  if (_this == nil), do: temp_right1 = 0, else: temp_right1 = _this._height
)
  if (temp_left1 > temp_right1), do: temp_result = Haxe.Ds.TreeNode.new(Haxe.Ds.TreeNode.new(l, k, v, r.left), r.key, r.value, r.right), else: temp_result = Haxe.Ds.TreeNode.new(Haxe.Ds.TreeNode.new(l, k, v, r.left.left), r.left.key, r.left.value, Haxe.Ds.TreeNode.new(r.left.right, r.key, r.value, r.right))
), else: (
  temp_left2 = nil
  (if (hl > hr), do: temp_left2 = hl, else: temp_left2 = hr)
  temp_result = Haxe.Ds.TreeNode.new(l, k, v, r, temp_left2 + 1)
)
  temp_result
)
  end

  @doc "Function compare"
  @spec compare(TInst(haxe.Ds.BalancedTree.K,[]).t(), TInst(haxe.Ds.BalancedTree.K,[]).t()) :: TAbstract(Int,[]).t()
  def compare(arg0, arg1) do
    Reflect.compare(k1, k2)
  end

end


defmodule TreeNode do
  @moduledoc """
  TreeNode module generated from Haxe
  
  
	A tree node of `haxe.ds.BalancedTree`.

  """

end
