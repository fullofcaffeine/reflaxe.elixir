defmodule InvalidChangeset do
  @moduledoc """
  Generated changeset for Invalid schema
  
  Provides validation and casting for Invalid data structures
  following Ecto changeset patterns with compile-time type safety.
  """
  
  import Ecto.Changeset
  alias Invalid
  
  @doc """
  Primary changeset function with comprehensive validation
  """
  def changeset(%Invalid{} = struct, attrs) do
    struct
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
  end
end