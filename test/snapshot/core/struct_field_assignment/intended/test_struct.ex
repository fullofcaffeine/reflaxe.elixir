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
  @doc "Generated from Haxe write"
  def write(%__MODULE__{} = struct, value) do
    g_array = Type.typeof(value)
    case (case g_array do :t_null -> 0; :t_int -> 1; :t_float -> 2; :t_bool -> 3; :t_object -> 4; :t_function -> 5; :t_class -> 6; :t_enum -> 7; :t_unknown -> 8; _ -> -1 end) do
      0 -> %{struct | field: struct.field <> "null"}
      1 -> %{struct | field: struct.field <> Std.string(value)}
      _ -> %{struct | field: struct.field <> "other"}
    end
  end

end
