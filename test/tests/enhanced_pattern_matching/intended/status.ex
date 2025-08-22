defmodule Status do
  @moduledoc """
  Status enum generated from Haxe
  
  
   * Enhanced Pattern Matching Test
   * Tests advanced pattern matching features including:
   * - Exhaustive checking with compile-time warnings
   * - Nested patterns with proper destructuring
   * - Complex guards with multiple conditions
   * - With statements for Result pattern handling
   * - Binary patterns for data processing
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :idle |
    {:working, term()} |
    {:completed, term(), term()} |
    {:failed, term(), term()}

  @doc "Creates idle enum value"
  @spec idle() :: :idle
  def idle(), do: :idle

  @doc """
  Creates working enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec working(term()) :: {:working, term()}
  def working(arg0) do
    {:working, arg0}
  end

  @doc """
  Creates completed enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec completed(term(), term()) :: {:completed, term(), term()}
  def completed(arg0, arg1) do
    {:completed, arg0, arg1}
  end

  @doc """
  Creates failed enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec failed(term(), term()) :: {:failed, term(), term()}
  def failed(arg0, arg1) do
    {:failed, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is idle variant"
  @spec is_idle(t()) :: boolean()
  def is_idle(:idle), do: true
  def is_idle(_), do: false

  @doc "Returns true if value is working variant"
  @spec is_working(t()) :: boolean()
  def is_working({:working, _}), do: true
  def is_working(_), do: false

  @doc "Returns true if value is completed variant"
  @spec is_completed(t()) :: boolean()
  def is_completed({:completed, _}), do: true
  def is_completed(_), do: false

  @doc "Returns true if value is failed variant"
  @spec is_failed(t()) :: boolean()
  def is_failed({:failed, _}), do: true
  def is_failed(_), do: false

  @doc "Extracts value from working variant, returns {:ok, value} or :error"
  @spec get_working_value(t()) :: {:ok, term()} | :error
  def get_working_value({:working, value}), do: {:ok, value}
  def get_working_value(_), do: :error

  @doc "Extracts value from completed variant, returns {:ok, value} or :error"
  @spec get_completed_value(t()) :: {:ok, {term(), term()}} | :error
  def get_completed_value({:completed, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_completed_value(_), do: :error

  @doc "Extracts value from failed variant, returns {:ok, value} or :error"
  @spec get_failed_value(t()) :: {:ok, {term(), term()}} | :error
  def get_failed_value({:failed, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_failed_value(_), do: :error

end
