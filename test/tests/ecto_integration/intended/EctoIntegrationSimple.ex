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
    field :id, :integer
    field :name, :string
    field :email, :string
    field :age, :integer
    field :active, :boolean
    has_many :posts, Post
    belongs_to :organization, Organization
    field :organization_id, :integer
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
    [:id, :name, :email, :age, :active, :organization_id, :updated_at]
  end

  defp required_fields do
    []
  end

end


defmodule Post do
  @moduledoc """
  Ecto schema module generated from Haxe @:schema class
  Table: posts
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "posts" do
    field :id, :integer
    field :title, :string
    field :content, :string
    field :published, :boolean
    field :view_count, :integer
    belongs_to :user, User
    field :user_id, :integer
    has_many :comments, Comment
    timestamps()
    field :updated_at, :string
  end

  @doc """
  Changeset function for Post schema
  """
  def changeset(%Post{} = post, attrs \\ %{}) do
    post
    |> cast(attrs, changeable_fields())
    |> validate_required(required_fields())
  end

  defp changeable_fields do
    [:id, :title, :content, :published, :view_count, :user_id, :updated_at]
  end

  defp required_fields do
    []
  end

end


defmodule Comment do
  @moduledoc """
  Ecto schema module generated from Haxe @:schema class
  Table: comments
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "comments" do
    field :id, :integer
    field :body, :string
    belongs_to :post, Post
    field :post_id, :integer
    belongs_to :user, User
    field :user_id, :integer
    timestamps()
    field :updated_at, :string
  end

  @doc """
  Changeset function for Comment schema
  """
  def changeset(%Comment{} = comment, attrs \\ %{}) do
    comment
    |> cast(attrs, changeable_fields())
    |> validate_required(required_fields())
  end

  defp changeable_fields do
    [:id, :body, :post_id, :user_id, :updated_at]
  end

  defp required_fields do
    []
  end

end


defmodule Organization do
  @moduledoc """
  Ecto schema module generated from Haxe @:schema class
  Table: organizations
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @derive {Phoenix.Param, key: :id}

  schema "organizations" do
    field :id, :integer
    field :name, :string
    field :domain, :string
    has_many :users, User
    timestamps()
    field :updated_at, :string
  end

  @doc """
  Changeset function for Organization schema
  """
  def changeset(%Organization{} = organization, attrs \\ %{}) do
    organization
    |> cast(attrs, changeable_fields())
    |> validate_required(required_fields())
  end

  defp changeable_fields do
    [:id, :name, :domain, :updated_at]
  end

  defp required_fields do
    []
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

defmodule Repo.Migrations.CreateUsersTable do
  @moduledoc """
  Generated migration for create_users table
  
  Creates create_users table with proper schema and indexes
  following Ecto migration patterns with compile-time validation.
  """
  
  use Ecto.Migration
  
  @doc """
  Run the migration - creates create_users table
  """
  def change do
    create table(:create_users) do

      timestamps()
    end
    
    create unique_index(:create_users, [:email])
  end
  
  @doc """
  Rollback migration - drops create_users table
  """
  def down do
    drop table(:create_users)
  end
end

defmodule UserQueries do
  @moduledoc """
  UserQueries module generated from Haxe
  """

  # Static functions
  @doc "Function active_users"
  @spec active_users() :: TDynamic(null).t()
  def active_users() do
    nil
  end

  @doc "Function users_with_posts"
  @spec users_with_posts() :: TDynamic(null).t()
  def users_with_posts() do
    nil
  end

  @doc "Function users_by_organization"
  @spec users_by_organization(TAbstract(Int,[]).t()) :: TDynamic(null).t()
  def users_by_organization(arg0) do
    nil
  end

end


defmodule Repo do
  @moduledoc """
  Repo module generated from Haxe
  """

  # Static functions
  @doc "Function all"
  @spec all(TDynamic(null).t()) :: TInst(Array,[TDynamic(null)]).t()
  def all(arg0) do
    []
  end

  @doc "Function get"
  @spec get(TDynamic(null).t(), TAbstract(Int,[]).t()) :: TDynamic(null).t()
  def get(arg0, arg1) do
    nil
  end

  @doc "Function insert"
  @spec insert(TDynamic(null).t()) :: TDynamic(null).t()
  def insert(arg0) do
    nil
  end

  @doc "Function update"
  @spec update(TDynamic(null).t()) :: TDynamic(null).t()
  def update(arg0) do
    nil
  end

  @doc "Function delete"
  @spec delete(TDynamic(null).t()) :: TDynamic(null).t()
  def delete(arg0) do
    nil
  end

  @doc "Function preload"
  @spec preload(TDynamic(null).t(), TInst(Array,[TInst(String,[])]).t()) :: TDynamic(null).t()
  def preload(arg0, arg1) do
    entity
  end

end


defmodule Accounts do
  @moduledoc """
  The Accounts context
  """

  import Ecto.Query, warn: false
  alias MyApp.Repo

  # Static functions
  @doc "Function list_users"
  @spec list_users() :: TInst(Array,[TDynamic(null)]).t()
  def list_users() do
    Repo.all(User)
  end

  @doc "Function get_user"
  @spec get_user(TAbstract(Int,[]).t()) :: TDynamic(null).t()
  def get_user(arg0) do
    Repo.get(User, id)
  end

  @doc "Function create_user"
  @spec create_user(TDynamic(null).t()) :: TDynamic(null).t()
  def create_user(arg0) do
    (
  user = User.new()
  changeset = UserChangeset.changeset(user, attrs)
  Repo.insert(changeset)
)
  end

  @doc "Function update_user"
  @spec update_user(TInst(User,[]).t(), TDynamic(null).t()) :: TDynamic(null).t()
  def update_user(arg0, arg1) do
    (
  changeset = UserChangeset.changeset(user, attrs)
  Repo.update(changeset)
)
  end

  @doc "Function delete_user"
  @spec delete_user(TInst(User,[]).t()) :: TDynamic(null).t()
  def delete_user(arg0) do
    Repo.delete(user)
  end

end


defmodule UserLive do
  use Phoenix.LiveView
  
  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div>LiveView generated from UserLive</div>
    """
  end
end

defmodule EctoIntegrationSimple do
  @moduledoc """
  EctoIntegrationSimple module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: TAbstract(Void,[]).t()
  def main() do
    (
  Log.trace("=== Ecto Integration Test Suite ===", %{fileName: "EctoIntegrationSimple.hx", lineNumber: 218, className: "EctoIntegrationSimple", methodName: "main"})
  Log.trace("Testing @:schema annotation...", %{fileName: "EctoIntegrationSimple.hx", lineNumber: 221, className: "EctoIntegrationSimple", methodName: "main"})
  user = User.new()
  user.name = "Test User"
  user.email = "test@example.com"
  Log.trace("Testing @:changeset annotation...", %{fileName: "EctoIntegrationSimple.hx", lineNumber: 227, className: "EctoIntegrationSimple", methodName: "main"})
  changeset = UserChangeset.changeset(user, %{name: "Updated", email: "new@example.com"})
  Log.trace("Testing @:migration annotation...", %{fileName: "EctoIntegrationSimple.hx", lineNumber: 231, className: "EctoIntegrationSimple", methodName: "main"})
  CreateUsersTable.up()
  Log.trace("Testing query functions...", %{fileName: "EctoIntegrationSimple.hx", lineNumber: 235, className: "EctoIntegrationSimple", methodName: "main"})
  active_users = UserQueries.activeUsers()
  Log.trace("Testing @:repository annotation...", %{fileName: "EctoIntegrationSimple.hx", lineNumber: 239, className: "EctoIntegrationSimple", methodName: "main"})
  users = Repo.all(User)
  Log.trace("Testing @:context annotation...", %{fileName: "EctoIntegrationSimple.hx", lineNumber: 243, className: "EctoIntegrationSimple", methodName: "main"})
  account_users = Accounts.list_users()
  Log.trace("Testing @:liveview with Ecto integration...", %{fileName: "EctoIntegrationSimple.hx", lineNumber: 247, className: "EctoIntegrationSimple", methodName: "main"})
  live_view = UserLive.new()
  Log.trace("Testing associations...", %{fileName: "EctoIntegrationSimple.hx", lineNumber: 251, className: "EctoIntegrationSimple", methodName: "main"})
  org = Organization.new()
  org.name = "Test Org"
  post = Post.new()
  post.title = "Test Post"
  comment = Comment.new()
  comment.body = "Test Comment"
  Log.trace("=== All Ecto Integration Tests Completed ===", %{fileName: "EctoIntegrationSimple.hx", lineNumber: 261, className: "EctoIntegrationSimple", methodName: "main"})
)
  end

end
