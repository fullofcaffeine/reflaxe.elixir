defmodule Todo do
  @moduledoc """
  Ecto schema module generated from Haxe @:schema class
  Table: todos
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "todos" do
    field :id, :integer
    field :title, :string
    field :description, :string
    field :completed, :boolean
    field :priority, :string
    field :due_date, :string
    field :tags, :string
    field :user_id, :integer
    timestamps()
    timestamps()
  end

  @doc """
  Changeset function for Todo schema
  """
  def changeset(%Todo{} = todo, attrs \\ %{}) do
    todo
    |> cast(attrs, changeable_fields())
    |> validate_required(required_fields())
  end

  defp changeable_fields do
    [:id, :title, :description, :completed, :priority, :due_date, :tags, :user_id]
  end

  defp required_fields do
    []
  end

end
