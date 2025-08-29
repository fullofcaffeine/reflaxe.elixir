defmodule PosException do
  @moduledoc """
    PosException struct generated from Haxe

      An exception that carry position information of a place where it was created.
  """

  defstruct [:pos_infos]

  @type t() :: %__MODULE__{
    pos_infos: PosInfos.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(String.t(), Null.t(), Null.t()) :: t()
  def new(arg0, arg1, arg2) do
    %__MODULE__{
      pos_infos: arg0
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc "Generated from Haxe toString"
  def format(%__MODULE__{} = struct) do
    "" + nil.toString() + " in " + struct.posInfos.className + "." + struct.posInfos.methodName + " at " + struct.posInfos.fileName + ":" + struct.posInfos.lineNumber
  end

end
