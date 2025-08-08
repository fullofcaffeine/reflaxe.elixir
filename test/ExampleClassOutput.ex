# Example class compilation output from ClassCompiler

# @:struct class - compiles to defstruct with typed fields
defmodule User do
  @moduledoc """
  User struct generated from Haxe
  
  User data structure
  
  This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:id, :name, :email, active: true, :metadata, :created_at]

  @type t() :: %__MODULE__{
    id: integer() | nil,
    name: String.t() | nil,
    email: String.t() | nil,
    active: boolean(),
    metadata: %{String.t() => String.t()} | nil,
    created_at: DateTime.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(integer(), String.t(), String.t()) :: t()
  def new(arg0, arg1, arg2) do
    %__MODULE__{
      id: arg0,
      name: arg1,
      email: arg2
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    struct |> Map.merge(changes) |> struct(__MODULE__, _1)
  end

  # Instance functions
  @doc "Updates the user's email address"
  @spec update_email(%__MODULE__{} = struct, String.t()) :: t()
  def update_email(%__MODULE__{} = struct, arg0) do
    %{struct | email: arg0}
  end

  # Static functions
  @doc "Finds all active users"
  @spec find_active() :: list(t())
  def find_active() do
    # TODO: Implement function body
    []
  end
end

# Regular class (not @:struct) - compiles to module with functions only
defmodule UserService do
  @moduledoc """
  UserService module generated from Haxe
  
  User service module
  """

  # Static functions
  @doc "Finds a user by ID"
  @spec find_by_id(integer()) :: User.t() | nil
  def find_by_id(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Creates a new user"
  @spec create_user(String.t(), String.t()) :: User.t()
  def create_user(arg0, arg1) do
    # TODO: Implement function body
    User.new(1, arg0, arg1)
  end
end

# Phoenix context class - module with CRUD functions
defmodule Accounts do
  @moduledoc """
  Accounts module generated from Haxe
  
  Accounts context
  """

  # Static functions
  @doc "Gets a user by ID"
  @spec get_user(integer()) :: User.t() | nil
  def get_user(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Lists all users"
  @spec list_users() :: list(User.t())
  def list_users() do
    # TODO: Implement function body
    []
  end

  @doc "Creates a user with attributes"
  @spec create_user(%{String.t() => String.t()}) :: User.t()
  def create_user(arg0) do
    # TODO: Implement function body
    nil
  end

  @doc "Updates a user with new attributes"
  @spec update_user(User.t(), %{String.t() => String.t()}) :: User.t()
  def update_user(arg0, arg1) do
    # TODO: Implement function body
    arg0
  end

  @doc "Deletes a user"
  @spec delete_user(User.t()) :: boolean()
  def delete_user(arg0) do
    # TODO: Implement function body
    false
  end
end

# Ecto schema class with @:struct and @:schema metadata
defmodule UserSchema do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  UserSchema struct generated from Haxe
  
  User database schema
  
  This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:id, :name, :email, :password_hash, :inserted_at, :updated_at]

  @type t() :: %__MODULE__{
    id: integer() | nil,
    name: String.t() | nil,
    email: String.t() | nil,
    password_hash: String.t() | nil,
    inserted_at: DateTime.t() | nil,
    updated_at: DateTime.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  # Instance functions
  @doc "Creates a changeset for the user"
  @spec changeset(%__MODULE__{} = struct, map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = struct, arg0) do
    struct
    |> cast(arg0, [:name, :email, :password_hash])
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end

# Config struct with final/immutable fields
defmodule Config do
  @moduledoc """
  Config struct generated from Haxe
  
  Configuration struct
  
  This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:key, :value, locked: false]

  @type t() :: %__MODULE__{
    key: String.t() | nil,
    value: String.t() | nil,
    locked: boolean()
  }

  @doc "Creates a new struct instance"
  @spec new(String.t(), String.t()) :: t()
  def new(arg0, arg1) do
    %__MODULE__{
      key: arg0,
      value: arg1
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    # Final fields would have additional validation here
    struct |> Map.merge(changes) |> struct(__MODULE__, _1)
  end
end

# Builder pattern with method chaining
defmodule Builder do
  @moduledoc """
  Builder struct generated from Haxe
  
  Builder pattern
  
  This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:name, :value, :options]

  @type t() :: %__MODULE__{
    name: String.t() | nil,
    value: integer() | nil,
    options: map() | nil
  }

  @doc "Creates a new struct with default values"
  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  # Instance functions
  @doc "Sets the name field"
  @spec with_name(%__MODULE__{} = struct, String.t()) :: t()
  def with_name(%__MODULE__{} = struct, arg0) do
    %{struct | name: arg0}
  end

  @doc "Sets the value field"
  @spec with_value(%__MODULE__{} = struct, integer()) :: t()
  def with_value(%__MODULE__{} = struct, arg0) do
    %{struct | value: arg0}
  end

  @doc "Builds the final result"
  @spec build(%__MODULE__{} = struct) :: term()
  def build(%__MODULE__{} = struct) do
    # TODO: Implement function body
    struct
  end
end