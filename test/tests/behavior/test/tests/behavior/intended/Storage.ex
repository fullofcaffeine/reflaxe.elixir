defmodule Storage do
  @moduledoc """
  Behavior module defining callback specifications.
  Generated from Haxe @:behaviour class.
  """

  @callback nit(any()) :: any()
  @callback et(String.t()) :: any()
  @callback ut(String.t(), any()) :: boolean()
  @callback elete(String.t()) :: boolean()
  @callback ist() :: list()

end


defmodule MemoryStorage do
  @moduledoc """
  MemoryStorage module generated from Haxe
  """

  # Instance functions
  @doc "Function init"
  @spec init(TDynamic(null).t()) :: TDynamic(null).t()
  def init(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Function get"
  @spec get(TInst(String,[]).t()) :: TDynamic(null).t()
  def get(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Function put"
  @spec put(TInst(String,[]).t(), TDynamic(null).t()) :: TAbstract(Bool,[]).t()
  def put(arg0, arg1) do
    # TODO: Implement function body
    nil
  end

  @doc "Function delete"
  @spec delete(TInst(String,[]).t()) :: TAbstract(Bool,[]).t()
  def delete(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Function list"
  @spec list() :: TInst(Array,[TInst(String,[])]).t()
  def list() do
    # TODO: Implement function body
    nil
  end

end


defmodule FileStorage do
  @moduledoc """
  FileStorage module generated from Haxe
  """

  # Instance functions
  @doc "Function init"
  @spec init(TDynamic(null).t()) :: TDynamic(null).t()
  def init(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Function get"
  @spec get(TInst(String,[]).t()) :: TDynamic(null).t()
  def get(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Function put"
  @spec put(TInst(String,[]).t(), TDynamic(null).t()) :: TAbstract(Bool,[]).t()
  def put(arg0, arg1) do
    # TODO: Implement function body
    nil
  end

  @doc "Function delete"
  @spec delete(TInst(String,[]).t()) :: TAbstract(Bool,[]).t()
  def delete(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Function list"
  @spec list() :: TInst(Array,[TInst(String,[])]).t()
  def list() do
    # TODO: Implement function body
    nil
  end

end


defmodule Logger do
  @moduledoc """
  Behavior module defining callback specifications.
  Generated from Haxe @:behaviour class.
  """

  @callback og(String.t()) :: any()
  @callback ebug(String.t()) :: any()
  @callback rror(String.t(), any()) :: any()

end


defmodule ConsoleLogger do
  @moduledoc """
  ConsoleLogger module generated from Haxe
  """

  # Instance functions
  @doc "Function log"
  @spec log(TInst(String,[]).t()) :: TAbstract(Void,[]).t()
  def log(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Function debug"
  @spec debug(TInst(String,[]).t()) :: TAbstract(Void,[]).t()
  def debug(arg0) do
    # TODO: Implement function body
    nil
  end

end
