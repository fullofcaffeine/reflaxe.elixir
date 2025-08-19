defmodule TodoPubSubTopic do
  @moduledoc """
  TodoPubSubTopic enum generated from Haxe
  
  
 * Type-safe PubSub topics for the todo application
 * 
 * Adding new topics requires:
 * 1. Add enum case here
 * 2. Add case to topicToString function
 * 3. Compiler ensures exhaustiveness
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :todo_updates |
    :user_activity |
    :system_notifications

  @doc "Creates todo_updates enum value"
  @spec todo_updates() :: :todo_updates
  def todo_updates(), do: :todo_updates

  @doc "Creates user_activity enum value"
  @spec user_activity() :: :user_activity
  def user_activity(), do: :user_activity

  @doc "Creates system_notifications enum value"
  @spec system_notifications() :: :system_notifications
  def system_notifications(), do: :system_notifications

  # Predicate functions for pattern matching
  @doc "Returns true if value is todo_updates variant"
  @spec is_todo_updates(t()) :: boolean()
  def is_todo_updates(:todo_updates), do: true
  def is_todo_updates(_), do: false

  @doc "Returns true if value is user_activity variant"
  @spec is_user_activity(t()) :: boolean()
  def is_user_activity(:user_activity), do: true
  def is_user_activity(_), do: false

  @doc "Returns true if value is system_notifications variant"
  @spec is_system_notifications(t()) :: boolean()
  def is_system_notifications(:system_notifications), do: true
  def is_system_notifications(_), do: false

end


defmodule TodoPubSubMessage do
  @moduledoc """
  TodoPubSubMessage enum generated from Haxe
  
  
 * Type-safe PubSub message types with compile-time validation
 * 
 * Each message type is strongly typed with required parameters.
 * Adding new messages requires updating parseMessage function.
 
  
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


defmodule BulkOperationType do
  @moduledoc """
  BulkOperationType enum generated from Haxe
  
  
 * Bulk operation types for type-safe bulk actions
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :complete_all |
    :delete_completed |
    {:set_priority, term()} |
    {:add_tag, term()} |
    {:remove_tag, term()}

  @doc "Creates complete_all enum value"
  @spec complete_all() :: :complete_all
  def complete_all(), do: :complete_all

  @doc "Creates delete_completed enum value"
  @spec delete_completed() :: :delete_completed
  def delete_completed(), do: :delete_completed

  @doc """
  Creates set_priority enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec set_priority(term()) :: {:set_priority, term()}
  def set_priority(arg0) do
    {:set_priority, arg0}
  end

  @doc """
  Creates add_tag enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec add_tag(term()) :: {:add_tag, term()}
  def add_tag(arg0) do
    {:add_tag, arg0}
  end

  @doc """
  Creates remove_tag enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec remove_tag(term()) :: {:remove_tag, term()}
  def remove_tag(arg0) do
    {:remove_tag, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is complete_all variant"
  @spec is_complete_all(t()) :: boolean()
  def is_complete_all(:complete_all), do: true
  def is_complete_all(_), do: false

  @doc "Returns true if value is delete_completed variant"
  @spec is_delete_completed(t()) :: boolean()
  def is_delete_completed(:delete_completed), do: true
  def is_delete_completed(_), do: false

  @doc "Returns true if value is set_priority variant"
  @spec is_set_priority(t()) :: boolean()
  def is_set_priority({:set_priority, _}), do: true
  def is_set_priority(_), do: false

  @doc "Returns true if value is add_tag variant"
  @spec is_add_tag(t()) :: boolean()
  def is_add_tag({:add_tag, _}), do: true
  def is_add_tag(_), do: false

  @doc "Returns true if value is remove_tag variant"
  @spec is_remove_tag(t()) :: boolean()
  def is_remove_tag({:remove_tag, _}), do: true
  def is_remove_tag(_), do: false

  @doc "Extracts value from set_priority variant, returns {:ok, value} or :error"
  @spec get_set_priority_value(t()) :: {:ok, term()} | :error
  def get_set_priority_value({:set_priority, value}), do: {:ok, value}
  def get_set_priority_value(_), do: :error

  @doc "Extracts value from add_tag variant, returns {:ok, value} or :error"
  @spec get_add_tag_value(t()) :: {:ok, term()} | :error
  def get_add_tag_value({:add_tag, value}), do: {:ok, value}
  def get_add_tag_value(_), do: :error

  @doc "Extracts value from remove_tag variant, returns {:ok, value} or :error"
  @spec get_remove_tag_value(t()) :: {:ok, term()} | :error
  def get_remove_tag_value({:remove_tag, value}), do: {:ok, value}
  def get_remove_tag_value(_), do: :error

end


defmodule AlertLevel do
  @moduledoc """
  AlertLevel enum generated from Haxe
  
  
 * Alert levels for system notifications
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :info |
    :warning |
    :error |
    :critical

  @doc "Creates info enum value"
  @spec info() :: :info
  def info(), do: :info

  @doc "Creates warning enum value"
  @spec warning() :: :warning
  def warning(), do: :warning

  @doc "Creates error enum value"
  @spec error() :: :error
  def error(), do: :error

  @doc "Creates critical enum value"
  @spec critical() :: :critical
  def critical(), do: :critical

  # Predicate functions for pattern matching
  @doc "Returns true if value is info variant"
  @spec is_info(t()) :: boolean()
  def is_info(:info), do: true
  def is_info(_), do: false

  @doc "Returns true if value is warning variant"
  @spec is_warning(t()) :: boolean()
  def is_warning(:warning), do: true
  def is_warning(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error(:error), do: true
  def is_error(_), do: false

  @doc "Returns true if value is critical variant"
  @spec is_critical(t()) :: boolean()
  def is_critical(:critical), do: true
  def is_critical(_), do: false

end
