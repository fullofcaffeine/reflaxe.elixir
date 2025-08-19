defmodule ApplicationStartType do
  @moduledoc """
  ApplicationStartType enum generated from Haxe
  
  
 * Application start type - normal, temporary, or permanent
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :normal |
    :temporary |
    :permanent

  @doc "Creates normal enum value"
  @spec normal() :: :normal
  def normal(), do: :normal

  @doc "Creates temporary enum value"
  @spec temporary() :: :temporary
  def temporary(), do: :temporary

  @doc "Creates permanent enum value"
  @spec permanent() :: :permanent
  def permanent(), do: :permanent

  # Predicate functions for pattern matching
  @doc "Returns true if value is normal variant"
  @spec is_normal(t()) :: boolean()
  def is_normal(:normal), do: true
  def is_normal(_), do: false

  @doc "Returns true if value is temporary variant"
  @spec is_temporary(t()) :: boolean()
  def is_temporary(:temporary), do: true
  def is_temporary(_), do: false

  @doc "Returns true if value is permanent variant"
  @spec is_permanent(t()) :: boolean()
  def is_permanent(:permanent), do: true
  def is_permanent(_), do: false

end


defmodule ApplicationResult do
  @moduledoc """
  ApplicationResult enum generated from Haxe
  
  
 * Application start result - success with state or error
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:ok, term()} |
    {:error, term()} |
    :ignore

  @doc """
  Creates ok enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec ok(term()) :: {:ok, term()}
  def ok(arg0) do
    {:ok, arg0}
  end

  @doc """
  Creates error enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec error(term()) :: {:error, term()}
  def error(arg0) do
    {:error, arg0}
  end

  @doc "Creates ignore enum value"
  @spec ignore() :: :ignore
  def ignore(), do: :ignore

  # Predicate functions for pattern matching
  @doc "Returns true if value is ok variant"
  @spec is_ok(t()) :: boolean()
  def is_ok({:ok, _}), do: true
  def is_ok(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Returns true if value is ignore variant"
  @spec is_ignore(t()) :: boolean()
  def is_ignore(:ignore), do: true
  def is_ignore(_), do: false

  @doc "Extracts value from ok variant, returns {:ok, value} or :error"
  @spec get_ok_value(t()) :: {:ok, term()} | :error
  def get_ok_value({:ok, value}), do: {:ok, value}
  def get_ok_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, term()} | :error
  def get_error_value({:error, value}), do: {:ok, value}
  def get_error_value(_), do: :error

end
