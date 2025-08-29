defmodule ChildSpecFormat do
  @moduledoc """
  ChildSpecFormat enum generated from Haxe
  
  
   * Child specification formats accepted by Supervisor.start_link
   * 
   * Elixir supervisors accept multiple formats:
   * - Module reference: `MyWorker`
   * - Tuple with args: `{MyWorker, [arg1, arg2]}`
   * - Full map specification
   * 
   * @:elixirIdiomatic - This annotation tells the compiler to generate
   * proper OTP child spec formats instead of generic tagged tuples.
   * This is necessary because OTP expects specific formats like
   * {Phoenix.PubSub, [name: "MyApp"]} rather than {:module_with_config, ...}
   
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:module_ref, term()} |
    {:module_with_args, term(), term()} |
    {:module_with_config, term(), term()} |
    {:full_spec, term()}

  @doc """
  Creates module_ref enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec module_ref(term()) :: {:module_ref, term()}
  def module_ref(arg0) do
    {:module_ref, arg0}
  end

  @doc """
  Creates module_with_args enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec module_with_args(term(), term()) :: {:module_with_args, term(), term()}
  def module_with_args(arg0, arg1) do
    {:module_with_args, arg0, arg1}
  end

  @doc """
  Creates module_with_config enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec module_with_config(term(), term()) :: {:module_with_config, term(), term()}
  def module_with_config(arg0, arg1) do
    {:module_with_config, arg0, arg1}
  end

  @doc """
  Creates full_spec enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec full_spec(term()) :: {:full_spec, term()}
  def full_spec(arg0) do
    {:full_spec, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is module_ref variant"
  @spec is_module_ref(t()) :: boolean()
  def is_module_ref({:module_ref, _}), do: true
  def is_module_ref(_), do: false

  @doc "Returns true if value is module_with_args variant"
  @spec is_module_with_args(t()) :: boolean()
  def is_module_with_args({:module_with_args, _}), do: true
  def is_module_with_args(_), do: false

  @doc "Returns true if value is module_with_config variant"
  @spec is_module_with_config(t()) :: boolean()
  def is_module_with_config({:module_with_config, _}), do: true
  def is_module_with_config(_), do: false

  @doc "Returns true if value is full_spec variant"
  @spec is_full_spec(t()) :: boolean()
  def is_full_spec({:full_spec, _}), do: true
  def is_full_spec(_), do: false

  @doc "Extracts value from module_ref variant, returns {:ok, value} or :error"
  @spec get_module_ref_value(t()) :: {:ok, term()} | :error
  def get_module_ref_value({:module_ref, value}), do: {:ok, value}
  def get_module_ref_value(_), do: :error

  @doc "Extracts value from module_with_args variant, returns {:ok, value} or :error"
  @spec get_module_with_args_value(t()) :: {:ok, {term(), term()}} | :error
  def get_module_with_args_value({:module_with_args, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_module_with_args_value(_), do: :error

  @doc "Extracts value from module_with_config variant, returns {:ok, value} or :error"
  @spec get_module_with_config_value(t()) :: {:ok, {term(), term()}} | :error
  def get_module_with_config_value({:module_with_config, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_module_with_config_value(_), do: :error

  @doc "Extracts value from full_spec variant, returns {:ok, value} or :error"
  @spec get_full_spec_value(t()) :: {:ok, term()} | :error
  def get_full_spec_value({:full_spec, value}), do: {:ok, value}
  def get_full_spec_value(_), do: :error

end
