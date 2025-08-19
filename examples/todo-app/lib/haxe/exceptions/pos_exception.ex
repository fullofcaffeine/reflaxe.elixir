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
    struct |> Map.merge(changes) |> struct(__MODULE__, _1)
  end

  # Instance functions
  @doc """
    Returns exception message.

  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = struct) do
    "" <> __MODULE__.toString() <> " in " <> __MODULE__.pos_infos.class_name <> "." <> __MODULE__.pos_infos.method_name <> " at " <> __MODULE__.pos_infos.file_name <> ":" <> Integer.to_string(__MODULE__.pos_infos.line_number)
  end

end
