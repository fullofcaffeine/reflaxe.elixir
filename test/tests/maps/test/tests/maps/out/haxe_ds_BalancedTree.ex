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
    # TODO: Implement function body
    nil
  end

  @doc "
		Returns the value `key` is bound to.

		If `key` is not bound to any value, `null` is returned.

		If `key` is null, the result is unspecified.
	"
  @spec get(TInst(haxe.Ds.BalancedTree.K,[]).t()) :: TAbstract(Null,[TInst(haxe.Ds.BalancedTree.V,[])]).t()
  def get(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "
		Tells if `key` is bound to a value.

		This method returns true even if `key` is bound to null.

		If `key` is null, the result is unspecified.
	"
  @spec exists(TInst(haxe.Ds.BalancedTree.K,[]).t()) :: TAbstract(Bool,[]).t()
  def exists(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "
		Iterates over the keys of `this` BalancedTree.

		This operation is performed in-order.
	"
  @spec keys() :: TType(Iterator,[TInst(haxe.Ds.BalancedTree.K,[])]).t()
  def keys() do
    # TODO: Implement function body
    nil
  end

  @doc "Function set_loop"
  @spec set_loop(TInst(haxe.Ds.BalancedTree.K,[]).t(), TInst(haxe.Ds.BalancedTree.V,[]).t(), TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t()) :: TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t()
  def set_loop(arg0, arg1, arg2) do
    # TODO: Implement function body
    nil
  end

  @doc "Function keys_loop"
  @spec keys_loop(TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t(), TInst(Array,[TInst(haxe.Ds.BalancedTree.K,[])]).t()) :: TAbstract(Void,[]).t()
  def keys_loop(arg0, arg1) do
    # TODO: Implement function body
    nil
  end

  @doc "Function balance"
  @spec balance(TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t(), TInst(haxe.Ds.BalancedTree.K,[]).t(), TInst(haxe.Ds.BalancedTree.V,[]).t(), TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t()) :: TInst(haxe.Ds.TreeNode,[TInst(haxe.Ds.BalancedTree.K,[]),TInst(haxe.Ds.BalancedTree.V,[])]).t()
  def balance(arg0, arg1, arg2, arg3) do
    # TODO: Implement function body
    nil
  end

  @doc "Function compare"
  @spec compare(TInst(haxe.Ds.BalancedTree.K,[]).t(), TInst(haxe.Ds.BalancedTree.K,[]).t()) :: TAbstract(Int,[]).t()
  def compare(arg0, arg1) do
    # TODO: Implement function body
    nil
  end

end


defmodule TreeNode do
  @moduledoc """
  TreeNode module generated from Haxe
  
  
	A tree node of `haxe.ds.BalancedTree`.

  """

end
