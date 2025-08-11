defmodule User do
  @moduledoc """
  Generated changeset for DefaultSchema schema
  
  Provides validation and casting for DefaultSchema data structures
  following Ecto changeset patterns with compile-time type safety.
  """
  
  import Ecto.Changeset
  alias DefaultSchema
  
  @doc """
  Primary changeset function with comprehensive validation
  """
  def changeset(%DefaultSchema{} = struct, attrs) do
    struct
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
  end
end