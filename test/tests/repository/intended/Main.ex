defmodule User do
  @moduledoc """
  Ecto schema module generated from Haxe @:schema class
  Table: users
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "users" do
    field :name, :string, null: false
    field :email, :string, null: false
    field :age, :integer
    field :active, :boolean, default: true
    timestamps()
    field :updated_at, :string
  end

  @doc """
  Changeset function for User schema
  """
  def changeset(%User{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, changeable_fields())
    |> validate_required(required_fields())
  end

  defp changeable_fields do
    [:name, :email, :age, :active, :updated_at]
  end

  defp required_fields do
    [:name, :email]
  end

end


defmodule UserChangeset do
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

defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "
     * Main function for compilation testing
     "
  @spec main() :: nil
  def main() do
    Log.trace("Repository pattern compilation test complete!", %{fileName: "Main.hx", lineNumber: 45, className: "Main", methodName: "main"})
  end

end


defmodule UserRepository do
  @moduledoc """
  UserRepository module generated from Haxe
  """

  # Static functions
  @doc "
     * List all users - compiles to Repo.all(User)
     "
  @spec get_all_users() :: Array.t()
  def get_all_users() do
    Repo.all(User)
  end

  @doc "
     * Get user by ID - compiles to Repo.get!(User, id)
     "
  @spec get_user(integer()) :: User.t()
  def get_user(arg0) do
    Repo.get(User, id)
  end

  @doc "
     * Get user by ID (raises if not found) - compiles to Repo.get!(User, id)
     "
  @spec get_user_bang(integer()) :: User.t()
  def get_user_bang(arg0) do
    Repo.get!(User, id)
  end

  @doc "
     * Create user - compiles to Repo.insert(changeset) with error tuple handling
     "
  @spec create_user(term()) :: term()
  def create_user(arg0) do
    (
  changeset = UserChangeset.changeset(nil, attrs)
  Repo.insert(changeset)
)
  end

  @doc "
     * Update user - compiles to Repo.update(changeset) with error tuple handling
     "
  @spec update_user(User.t(), term()) :: term()
  def update_user(arg0, arg1) do
    (
  changeset = UserChangeset.changeset(user, attrs)
  Repo.update(changeset)
)
  end

  @doc "
     * Delete user - compiles to Repo.delete(user) with error tuple handling
     "
  @spec delete_user(User.t()) :: term()
  def delete_user(arg0) do
    Repo.delete(user)
  end

  @doc "
     * Preload associations - compiles to Repo.preload(user, [:posts])
     "
  @spec preload_posts(User.t()) :: User.t()
  def preload_posts(arg0) do
    Repo.preload(user, ["posts"])
  end

  @doc "
     * Count users - compiles to Repo.aggregate(User, :count)
     "
  @spec count_users() :: integer()
  def count_users() do
    Repo.aggregate(User, "count")
  end

  @doc "
     * Get first user - compiles to Repo.one(query)
     "
  @spec get_first_user() :: User.t()
  def get_first_user() do
    Repo.one(User)
  end

end
