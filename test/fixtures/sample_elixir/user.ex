defmodule MyApp.User do
  @moduledoc """
  User model with Phoenix/Ecto patterns for testing extern generation.
  """

  @type t :: %__MODULE__{
    id: integer() | nil,
    name: String.t(),
    email: String.t(),
    age: integer() | nil,
    active: boolean()
  }

  defstruct [:id, :name, :email, :age, active: true]

  @spec create(String.t(), String.t()) :: t()
  def create(name, email) do
    %__MODULE__{
      name: name,
      email: email
    }
  end

  @spec create_with_age(String.t(), String.t(), integer()) :: t()
  def create_with_age(name, email, age) do
    %__MODULE__{
      name: name,
      email: email,
      age: age
    }
  end

  @spec get_by_id(integer()) :: {:ok, t()} | {:error, :not_found}
  def get_by_id(id) do
    # Mock implementation
    {:ok, %__MODULE__{id: id, name: "John", email: "john@example.com"}}
  end

  @spec update_email(t(), String.t()) :: t()
  def update_email(user, new_email) do
    %{user | email: new_email}
  end

  @spec activate(t()) :: t()
  def activate(user) do
    %{user | active: true}
  end

  @spec deactivate(t()) :: t()
  def deactivate(user) do
    %{user | active: false}
  end

  @spec is_adult?(t()) :: boolean()
  def is_adult?(%{age: age}) when is_integer(age) do
    age >= 18
  end

  def is_adult?(_user) do
    false
  end

  @spec list_all() :: list(t())
  def list_all() do
    []
  end

  @spec validate_email(String.t()) :: :ok | {:error, String.t()}
  def validate_email(email) when is_binary(email) do
    if String.contains?(email, "@") do
      :ok
    else
      {:error, "Invalid email format"}
    end
  end

  def some_function_without_spec(x) do
    x
  end
end