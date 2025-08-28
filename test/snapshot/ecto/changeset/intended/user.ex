defmodule User do
  @moduledoc """
  Generated changeset for User schema
  
  Provides validation and casting for User data structures
  following Ecto changeset patterns with compile-time type safety.
  """
  
  import Ecto.Changeset
  alias User
  
  @doc """
  Primary changeset function with comprehensive validation
  """
  def changeset(%User{} = struct, attrs) do
    struct
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
  end
end