defmodule PubSubMessageType do
  @moduledoc """
  PubSubMessageType enum generated from Haxe
  
  
 * Type-safe PubSub message types - compile-time validation of message structure
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:todo_created, term()} |
    {:todo_updated, term()} |
    {:todo_deleted, term()} |
    {:bulk_update, term()} |
    {:user_online, term()} |
    {:user_offline, term()} |
    {:system_alert, term(), term()}

  @doc """
  Creates todo_created enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec todo_created(term()) :: {:todo_created, term()}
  def todo_created(arg0) do
    {:todo_created, arg0}
  end

  @doc """
  Creates todo_updated enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec todo_updated(term()) :: {:todo_updated, term()}
  def todo_updated(arg0) do
    {:todo_updated, arg0}
  end

  @doc """
  Creates todo_deleted enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec todo_deleted(term()) :: {:todo_deleted, term()}
  def todo_deleted(arg0) do
    {:todo_deleted, arg0}
  end

  @doc """
  Creates bulk_update enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec bulk_update(term()) :: {:bulk_update, term()}
  def bulk_update(arg0) do
    {:bulk_update, arg0}
  end

  @doc """
  Creates user_online enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec user_online(term()) :: {:user_online, term()}
  def user_online(arg0) do
    {:user_online, arg0}
  end

  @doc """
  Creates user_offline enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec user_offline(term()) :: {:user_offline, term()}
  def user_offline(arg0) do
    {:user_offline, arg0}
  end

  @doc """
  Creates system_alert enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec system_alert(term(), term()) :: {:system_alert, term(), term()}
  def system_alert(arg0, arg1) do
    {:system_alert, arg0, arg1}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is todo_created variant"
  @spec is_todo_created(t()) :: boolean()
  def is_todo_created({:todo_created, _}), do: true
  def is_todo_created(_), do: false

  @doc "Returns true if value is todo_updated variant"
  @spec is_todo_updated(t()) :: boolean()
  def is_todo_updated({:todo_updated, _}), do: true
  def is_todo_updated(_), do: false

  @doc "Returns true if value is todo_deleted variant"
  @spec is_todo_deleted(t()) :: boolean()
  def is_todo_deleted({:todo_deleted, _}), do: true
  def is_todo_deleted(_), do: false

  @doc "Returns true if value is bulk_update variant"
  @spec is_bulk_update(t()) :: boolean()
  def is_bulk_update({:bulk_update, _}), do: true
  def is_bulk_update(_), do: false

  @doc "Returns true if value is user_online variant"
  @spec is_user_online(t()) :: boolean()
  def is_user_online({:user_online, _}), do: true
  def is_user_online(_), do: false

  @doc "Returns true if value is user_offline variant"
  @spec is_user_offline(t()) :: boolean()
  def is_user_offline({:user_offline, _}), do: true
  def is_user_offline(_), do: false

  @doc "Returns true if value is system_alert variant"
  @spec is_system_alert(t()) :: boolean()
  def is_system_alert({:system_alert, _}), do: true
  def is_system_alert(_), do: false

  @doc "Extracts value from todo_created variant, returns {:ok, value} or :error"
  @spec get_todo_created_value(t()) :: {:ok, term()} | :error
  def get_todo_created_value({:todo_created, value}), do: {:ok, value}
  def get_todo_created_value(_), do: :error

  @doc "Extracts value from todo_updated variant, returns {:ok, value} or :error"
  @spec get_todo_updated_value(t()) :: {:ok, term()} | :error
  def get_todo_updated_value({:todo_updated, value}), do: {:ok, value}
  def get_todo_updated_value(_), do: :error

  @doc "Extracts value from todo_deleted variant, returns {:ok, value} or :error"
  @spec get_todo_deleted_value(t()) :: {:ok, term()} | :error
  def get_todo_deleted_value({:todo_deleted, value}), do: {:ok, value}
  def get_todo_deleted_value(_), do: :error

  @doc "Extracts value from bulk_update variant, returns {:ok, value} or :error"
  @spec get_bulk_update_value(t()) :: {:ok, term()} | :error
  def get_bulk_update_value({:bulk_update, value}), do: {:ok, value}
  def get_bulk_update_value(_), do: :error

  @doc "Extracts value from user_online variant, returns {:ok, value} or :error"
  @spec get_user_online_value(t()) :: {:ok, term()} | :error
  def get_user_online_value({:user_online, value}), do: {:ok, value}
  def get_user_online_value(_), do: :error

  @doc "Extracts value from user_offline variant, returns {:ok, value} or :error"
  @spec get_user_offline_value(t()) :: {:ok, term()} | :error
  def get_user_offline_value({:user_offline, value}), do: {:ok, value}
  def get_user_offline_value(_), do: :error

  @doc "Extracts value from system_alert variant, returns {:ok, value} or :error"
  @spec get_system_alert_value(t()) :: {:ok, {term(), term()}} | :error
  def get_system_alert_value({:system_alert, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_system_alert_value(_), do: :error

end
