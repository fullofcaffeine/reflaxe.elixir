defmodule Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    Comment struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:id, :body, :post, :post_id, :user, :user_id, :inserted_at, :updated_at]

  @type t() :: %__MODULE__{
    id: integer() | nil,
    body: String.t() | nil,
    post: term() | nil,
    post_id: integer() | nil,
    user: term() | nil,
    user_id: integer() | nil,
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
