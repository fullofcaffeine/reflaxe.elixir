defmodule RestartType do
  @moduledoc """
  RestartType enum generated from Haxe
  
  
 * Child restart strategy
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :permanent |
    :temporary |
    :transient

  @doc "Creates permanent enum value"
  @spec permanent() :: :permanent
  def permanent(), do: :permanent

  @doc "Creates temporary enum value"
  @spec temporary() :: :temporary
  def temporary(), do: :temporary

  @doc "Creates transient enum value"
  @spec transient() :: :transient
  def transient(), do: :transient

  # Predicate functions for pattern matching
  @doc "Returns true if value is permanent variant"
  @spec is_permanent(t()) :: boolean()
  def is_permanent(:permanent), do: true
  def is_permanent(_), do: false

  @doc "Returns true if value is temporary variant"
  @spec is_temporary(t()) :: boolean()
  def is_temporary(:temporary), do: true
  def is_temporary(_), do: false

  @doc "Returns true if value is transient variant"
  @spec is_transient(t()) :: boolean()
  def is_transient(:transient), do: true
  def is_transient(_), do: false

end


defmodule ShutdownType do
  @moduledoc """
  ShutdownType enum generated from Haxe
  
  
 * Child shutdown strategy
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :brutal |
    {:timeout, term()} |
    :infinity

  @doc "Creates brutal enum value"
  @spec brutal() :: :brutal
  def brutal(), do: :brutal

  @doc """
  Creates timeout enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec timeout(term()) :: {:timeout, term()}
  def timeout(arg0) do
    {:timeout, arg0}
  end

  @doc "Creates infinity enum value"
  @spec infinity() :: :infinity
  def infinity(), do: :infinity

  # Predicate functions for pattern matching
  @doc "Returns true if value is brutal variant"
  @spec is_brutal(t()) :: boolean()
  def is_brutal(:brutal), do: true
  def is_brutal(_), do: false

  @doc "Returns true if value is timeout variant"
  @spec is_timeout(t()) :: boolean()
  def is_timeout({:timeout, _}), do: true
  def is_timeout(_), do: false

  @doc "Returns true if value is infinity variant"
  @spec is_infinity(t()) :: boolean()
  def is_infinity(:infinity), do: true
  def is_infinity(_), do: false

  @doc "Extracts value from timeout variant, returns {:ok, value} or :error"
  @spec get_timeout_value(t()) :: {:ok, term()} | :error
  def get_timeout_value({:timeout, value}), do: {:ok, value}
  def get_timeout_value(_), do: :error

end


defmodule ChildType do
  @moduledoc """
  ChildType enum generated from Haxe
  
  
 * Child type
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :worker |
    :supervisor

  @doc "Creates worker enum value"
  @spec worker() :: :worker
  def worker(), do: :worker

  @doc "Creates supervisor enum value"
  @spec supervisor() :: :supervisor
  def supervisor(), do: :supervisor

  # Predicate functions for pattern matching
  @doc "Returns true if value is worker variant"
  @spec is_worker(t()) :: boolean()
  def is_worker(:worker), do: true
  def is_worker(_), do: false

  @doc "Returns true if value is supervisor variant"
  @spec is_supervisor(t()) :: boolean()
  def is_supervisor(:supervisor), do: true
  def is_supervisor(_), do: false

end


defmodule SupervisorStrategy do
  @moduledoc """
  SupervisorStrategy enum generated from Haxe
  
  
 * Supervisor restart strategy
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :one_for_one |
    :one_for_all |
    :rest_for_one |
    :simple_one_for_one

  @doc "Creates one_for_one enum value"
  @spec one_for_one() :: :one_for_one
  def one_for_one(), do: :one_for_one

  @doc "Creates one_for_all enum value"
  @spec one_for_all() :: :one_for_all
  def one_for_all(), do: :one_for_all

  @doc "Creates rest_for_one enum value"
  @spec rest_for_one() :: :rest_for_one
  def rest_for_one(), do: :rest_for_one

  @doc "Creates simple_one_for_one enum value"
  @spec simple_one_for_one() :: :simple_one_for_one
  def simple_one_for_one(), do: :simple_one_for_one

  # Predicate functions for pattern matching
  @doc "Returns true if value is one_for_one variant"
  @spec is_one_for_one(t()) :: boolean()
  def is_one_for_one(:one_for_one), do: true
  def is_one_for_one(_), do: false

  @doc "Returns true if value is one_for_all variant"
  @spec is_one_for_all(t()) :: boolean()
  def is_one_for_all(:one_for_all), do: true
  def is_one_for_all(_), do: false

  @doc "Returns true if value is rest_for_one variant"
  @spec is_rest_for_one(t()) :: boolean()
  def is_rest_for_one(:rest_for_one), do: true
  def is_rest_for_one(_), do: false

  @doc "Returns true if value is simple_one_for_one variant"
  @spec is_simple_one_for_one(t()) :: boolean()
  def is_simple_one_for_one(:simple_one_for_one), do: true
  def is_simple_one_for_one(_), do: false

end
