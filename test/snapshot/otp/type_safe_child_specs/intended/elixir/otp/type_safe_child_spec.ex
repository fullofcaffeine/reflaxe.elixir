defmodule TypeSafeChildSpec do
  @moduledoc """
  TypeSafeChildSpec enum generated from Haxe
  
  
   * Type-safe child specification enum
   * 
   * Each variant represents a specific type of child process with
   * properly typed configuration options.
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:pub_sub, term()} |
    {:repo, term()} |
    {:endpoint, term(), term()} |
    {:telemetry, term()} |
    {:presence, term()} |
    {:custom, term(), term(), term(), term()} |
    {:legacy, term()}

  @doc """
  Creates pub_sub enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec pub_sub(term()) :: {:pub_sub, term()}
  def pub_sub(arg0) do
    {:pub_sub, arg0}
  end

  @doc """
  Creates repo enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec repo(term()) :: {:repo, term()}
  def repo(arg0) do
    {:repo, arg0}
  end

  @doc """
  Creates endpoint enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec endpoint(term(), term()) :: {:endpoint, term(), term()}
  def endpoint(arg0, arg1) do
    {:endpoint, arg0, arg1}
  end

  @doc """
  Creates telemetry enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec telemetry(term()) :: {:telemetry, term()}
  def telemetry(arg0) do
    {:telemetry, arg0}
  end

  @doc """
  Creates presence enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec presence(term()) :: {:presence, term()}
  def presence(arg0) do
    {:presence, arg0}
  end

  @doc """
  Creates custom enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
    - `arg3`: term()
  """
  @spec custom(term(), term(), term(), term()) :: {:custom, term(), term(), term(), term()}
  def custom(arg0, arg1, arg2, arg3) do
    {:custom, arg0, arg1, arg2, arg3}
  end

  @doc """
  Creates legacy enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec legacy(term()) :: {:legacy, term()}
  def legacy(arg0) do
    {:legacy, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is pub_sub variant"
  @spec is_pub_sub(t()) :: boolean()
  def is_pub_sub({:pub_sub, _}), do: true
  def is_pub_sub(_), do: false

  @doc "Returns true if value is repo variant"
  @spec is_repo(t()) :: boolean()
  def is_repo({:repo, _}), do: true
  def is_repo(_), do: false

  @doc "Returns true if value is endpoint variant"
  @spec is_endpoint(t()) :: boolean()
  def is_endpoint({:endpoint, _}), do: true
  def is_endpoint(_), do: false

  @doc "Returns true if value is telemetry variant"
  @spec is_telemetry(t()) :: boolean()
  def is_telemetry({:telemetry, _}), do: true
  def is_telemetry(_), do: false

  @doc "Returns true if value is presence variant"
  @spec is_presence(t()) :: boolean()
  def is_presence({:presence, _}), do: true
  def is_presence(_), do: false

  @doc "Returns true if value is custom variant"
  @spec is_custom(t()) :: boolean()
  def is_custom({:custom, _}), do: true
  def is_custom(_), do: false

  @doc "Returns true if value is legacy variant"
  @spec is_legacy(t()) :: boolean()
  def is_legacy({:legacy, _}), do: true
  def is_legacy(_), do: false

  @doc "Extracts value from pub_sub variant, returns {:ok, value} or :error"
  @spec get_pub_sub_value(t()) :: {:ok, term()} | :error
  def get_pub_sub_value({:pub_sub, value}), do: {:ok, value}
  def get_pub_sub_value(_), do: :error

  @doc "Extracts value from repo variant, returns {:ok, value} or :error"
  @spec get_repo_value(t()) :: {:ok, term()} | :error
  def get_repo_value({:repo, value}), do: {:ok, value}
  def get_repo_value(_), do: :error

  @doc "Extracts value from endpoint variant, returns {:ok, value} or :error"
  @spec get_endpoint_value(t()) :: {:ok, {term(), term()}} | :error
  def get_endpoint_value({:endpoint, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_endpoint_value(_), do: :error

  @doc "Extracts value from telemetry variant, returns {:ok, value} or :error"
  @spec get_telemetry_value(t()) :: {:ok, term()} | :error
  def get_telemetry_value({:telemetry, value}), do: {:ok, value}
  def get_telemetry_value(_), do: :error

  @doc "Extracts value from presence variant, returns {:ok, value} or :error"
  @spec get_presence_value(t()) :: {:ok, term()} | :error
  def get_presence_value({:presence, value}), do: {:ok, value}
  def get_presence_value(_), do: :error

  @doc "Extracts value from custom variant, returns {:ok, value} or :error"
  @spec get_custom_value(t()) :: {:ok, {term(), term(), term(), term()}} | :error
  def get_custom_value({:custom, arg0, arg1, arg2, arg3}), do: {:ok, {arg0, arg1, arg2, arg3}}
  def get_custom_value(_), do: :error

  @doc "Extracts value from legacy variant, returns {:ok, value} or :error"
  @spec get_legacy_value(t()) :: {:ok, term()} | :error
  def get_legacy_value({:legacy, value}), do: {:ok, value}
  def get_legacy_value(_), do: :error

end
