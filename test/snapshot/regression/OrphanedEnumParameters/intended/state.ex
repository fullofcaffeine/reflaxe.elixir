defmodule State do
  @moduledoc """
  State enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:loading, term()} |
    {:processing, term()} |
    {:complete, term()} |
    {:error, term()}

  @doc """
  Creates loading enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec loading(term()) :: {:loading, term()}
  def loading(arg0) do
    {:loading, arg0}
  end

  @doc """
  Creates processing enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec processing(term()) :: {:processing, term()}
  def processing(arg0) do
    {:processing, arg0}
  end

  @doc """
  Creates complete enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec complete(term()) :: {:complete, term()}
  def complete(arg0) do
    {:complete, arg0}
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

  # Predicate functions for pattern matching
  @doc "Returns true if value is loading variant"
  @spec is_loading(t()) :: boolean()
  def is_loading({:loading, _}), do: true
  def is_loading(_), do: false

  @doc "Returns true if value is processing variant"
  @spec is_processing(t()) :: boolean()
  def is_processing({:processing, _}), do: true
  def is_processing(_), do: false

  @doc "Returns true if value is complete variant"
  @spec is_complete(t()) :: boolean()
  def is_complete({:complete, _}), do: true
  def is_complete(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error({:error, _}), do: true
  def is_error(_), do: false

  @doc "Extracts value from loading variant, returns {:ok, value} or :error"
  @spec get_loading_value(t()) :: {:ok, term()} | :error
  def get_loading_value({:loading, value}), do: {:ok, value}
  def get_loading_value(_), do: :error

  @doc "Extracts value from processing variant, returns {:ok, value} or :error"
  @spec get_processing_value(t()) :: {:ok, term()} | :error
  def get_processing_value({:processing, value}), do: {:ok, value}
  def get_processing_value(_), do: :error

  @doc "Extracts value from complete variant, returns {:ok, value} or :error"
  @spec get_complete_value(t()) :: {:ok, term()} | :error
  def get_complete_value({:complete, value}), do: {:ok, value}
  def get_complete_value(_), do: :error

  @doc "Extracts value from error variant, returns {:ok, value} or :error"
  @spec get_error_value(t()) :: {:ok, term()} | :error
  def get_error_value({:error, value}), do: {:ok, value}
  def get_error_value(_), do: :error

end
