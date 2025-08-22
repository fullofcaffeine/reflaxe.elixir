defmodule Post do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
    Post struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:id, :title, :content, published: true, view_count: 0, :user, :user_id, :comments, :inserted_at, :updated_at]

  @type t() :: %__MODULE__{
    id: integer() | nil,
    title: String.t() | nil,
    content: String.t() | nil,
    published: boolean(),
    view_count: integer(),
    user: term() | nil,
    user_id: integer() | nil,
    comments: Array.t() | nil,
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
