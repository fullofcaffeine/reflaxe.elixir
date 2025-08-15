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
  def init(config) do
    %{ok: __MODULE__}
  end

  @doc "Function get"
  @spec get(String.t()) :: term()
  def get(key) do
    this = __MODULE__.data
    temp_result = this.get(key)
    temp_result
  end

  @doc "Function put"
  @spec put(String.t(), term()) :: boolean()
  def put(key, value) do
    this = __MODULE__.data
    this.set(key, value)
    true
  end

  @doc "Function delete"
  @spec delete(String.t()) :: boolean()
  def delete(key) do
    this = __MODULE__.data
    temp_result = this.remove(key)
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
  def init(config) do
    if (config.path != nil), do: __MODULE__.base_path = config.path, else: nil
    %{ok: __MODULE__}
  end

  @doc "Function get"
  @spec get(String.t()) :: term()
  def get(key) do
    nil
  end

  @doc "Function put"
  @spec put(String.t(), term()) :: boolean()
  def put(key, value) do
    true
  end

  @doc "Function delete"
  @spec delete(String.t()) :: boolean()
  def delete(key) do
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
  def log(message) do
    Log.trace("[LOG] " <> message, %{fileName: "Storage.hx", lineNumber: 103, className: "ConsoleLogger", methodName: "log"})
  end

  @doc "Function debug"
  @spec debug(String.t()) :: nil
  def debug(message) do
    Log.trace("[DEBUG] " <> message, %{fileName: "Storage.hx", lineNumber: 108, className: "ConsoleLogger", methodName: "debug"})
  end

end
