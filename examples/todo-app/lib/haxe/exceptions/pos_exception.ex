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
  @doc """
    Returns exception message.

  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = struct) do
    "" <> "Exception" <> " in " <> struct.pos_infos.class_name <> "." <> struct.pos_infos.method_name <> " at " <> struct.pos_infos.file_name <> ":" <> to_string(struct.pos_infos.line_number)
  end

end
