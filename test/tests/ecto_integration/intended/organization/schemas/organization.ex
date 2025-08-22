defmodule Organization do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    Organization struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:id, :name, :domain, :users, :inserted_at, :updated_at]

  @type t() :: %__MODULE__{
    id: integer() | nil,
    name: String.t() | nil,
    domain: String.t() | nil,
    users: Array.t() | nil,
    inserted_at: term() | nil,
    updated_at: term() | nil
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

end
