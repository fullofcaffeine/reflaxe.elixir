defmodule TestStruct do
  @moduledoc """
    TestStruct struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:field]

  @type t() :: %__MODULE__{
    field: String.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new() :: t()
  def new() do
    %__MODULE__{
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc "Function write"
  @spec write(t(), term()) :: t()
  def write(%__MODULE__{} = struct, value) do
    (
          g_array = Type.typeof(value)
          case g_array do
      :t_null -> struct = %{struct | field: struct.field <> "null"}
      :t_int -> struct = %{struct | field: struct.field <> Std.string(value)}
      _ -> struct = %{struct | field: struct.field <> "other"}
    end
        )
    struct
  end

end
