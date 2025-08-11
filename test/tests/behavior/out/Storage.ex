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
    %{ok: self()}
  end

  @doc "Function get"
  @spec get(TInst(String,[]).t()) :: TDynamic(null).t()
  def get(arg0) do
    (
  temp_result = nil
  (
  this1 = self().data
  temp_result = # TODO: Implement expression type: TCast.get(key)
)
  temp_result
)
  end

  @doc "Function put"
  @spec put(TInst(String,[]).t(), TDynamic(null).t()) :: TAbstract(Bool,[]).t()
  def put(arg0, arg1) do
    (
  (
  this1 = self().data
  # TODO: Implement expression type: TCast.set(key, value)
)
  true
)
  end

  @doc "Function delete"
  @spec delete(TInst(String,[]).t()) :: TAbstract(Bool,[]).t()
  def delete(arg0) do
    (
  temp_result = nil
  (
  this1 = self().data
  temp_result = # TODO: Implement expression type: TCast.remove(key)
)
  temp_result
)
  end

  @doc "Function list"
  @spec list() :: TInst(Array,[TInst(String,[])]).t()
  def list() do
    (
  temp_result = nil
  (
  _g = []
  (
  temp_iterator = nil
  (
  this1 = self().data
  temp_iterator = # TODO: Implement expression type: TCast.keys()
)
  k = temp_iterator
  # TODO: Implement expression type: TWhile
)
  temp_result = _g
)
  temp_result
)
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
    (
  if (config.path != nil), do: self().base_path = config.path, else: nil
  %{ok: self()}
)
  end

  @doc "Function get"
  @spec get(TInst(String,[]).t()) :: TDynamic(null).t()
  def get(arg0) do
    nil
  end

  @doc "Function put"
  @spec put(TInst(String,[]).t(), TDynamic(null).t()) :: TAbstract(Bool,[]).t()
  def put(arg0, arg1) do
    true
  end

  @doc "Function delete"
  @spec delete(TInst(String,[]).t()) :: TAbstract(Bool,[]).t()
  def delete(arg0) do
    true
  end

  @doc "Function list"
  @spec list() :: TInst(Array,[TInst(String,[])]).t()
  def list() do
    []
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
    Log.trace("[LOG] " + message, %{fileName: "Storage.hx", lineNumber: 103, className: "ConsoleLogger", methodName: "log"})
  end

  @doc "Function debug"
  @spec debug(TInst(String,[]).t()) :: TAbstract(Void,[]).t()
  def debug(arg0) do
    Log.trace("[DEBUG] " + message, %{fileName: "Storage.hx", lineNumber: 108, className: "ConsoleLogger", methodName: "debug"})
  end

end
