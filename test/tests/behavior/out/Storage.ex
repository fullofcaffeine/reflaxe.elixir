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
  use Bitwise
  @moduledoc """
  MemoryStorage module generated from Haxe
  """

  # Instance functions
  @doc "Function init"
  @spec init(term()) :: term()
  def init(arg0) do
    %{ok: __MODULE__}
  end

  @doc "Function get"
  @spec get(String.t()) :: term()
  def get(arg0) do
    this = __MODULE__.data
temp_result = this.get(arg0)
temp_result
  end

  @doc "Function put"
  @spec put(String.t(), term()) :: boolean()
  def put(arg0, arg1) do
    this = __MODULE__.data
this.set(arg0, arg1)
true
  end

  @doc "Function delete"
  @spec delete(String.t()) :: boolean()
  def delete(arg0) do
    this = __MODULE__.data
temp_result = this.remove(arg0)
temp_result
  end

  @doc "Function list"
  @spec list() :: Array.t()
  def list() do
    _g = []
this = __MODULE__.data
temp_iterator = this.keys()
k = temp_iterator
(
  try do
    loop_fn = fn ->
      if (k.hasNext()) do
        try do
          k = k.next()
_g ++ [k]
          loop_fn.()
        catch
          :break -> nil
          :continue -> loop_fn.()
        end
      end
    end
    loop_fn.()
  catch
    :break -> nil
  end
)
_g
  end

end


defmodule FileStorage do
  use Bitwise
  @moduledoc """
  FileStorage module generated from Haxe
  """

  # Instance functions
  @doc "Function init"
  @spec init(term()) :: term()
  def init(arg0) do
    if (arg0.path != nil), do: __MODULE__.base_path = arg0.path, else: nil
%{ok: __MODULE__}
  end

  @doc "Function get"
  @spec get(String.t()) :: term()
  def get(arg0) do
    nil
  end

  @doc "Function put"
  @spec put(String.t(), term()) :: boolean()
  def put(arg0, arg1) do
    true
  end

  @doc "Function delete"
  @spec delete(String.t()) :: boolean()
  def delete(arg0) do
    true
  end

  @doc "Function list"
  @spec list() :: Array.t()
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
  use Bitwise
  @moduledoc """
  ConsoleLogger module generated from Haxe
  """

  # Instance functions
  @doc "Function log"
  @spec log(String.t()) :: nil
  def log(arg0) do
    Log.trace("[LOG] " <> arg0, %{fileName: "Storage.hx", lineNumber: 103, className: "ConsoleLogger", methodName: "log"})
  end

  @doc "Function debug"
  @spec debug(String.t()) :: nil
  def debug(arg0) do
    Log.trace("[DEBUG] " <> arg0, %{fileName: "Storage.hx", lineNumber: 108, className: "ConsoleLogger", methodName: "debug"})
  end

end
