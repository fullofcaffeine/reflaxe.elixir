defmodule PubSubTopic do
  @moduledoc """
  PubSubTopic enum generated from Haxe
  
  
 * Type-safe PubSub topics - prevents typos and invalid topic strings
 
  
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


defmodule SortDirection do
  @moduledoc """
  SortDirection enum generated from Haxe
  
  
 * Sort direction
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :asc |
    :desc

  @doc "Creates asc enum value"
  @spec asc() :: :asc
  def asc(), do: :asc

  @doc "Creates desc enum value"
  @spec desc() :: :desc
  def desc(), do: :desc

  # Predicate functions for pattern matching
  @doc "Returns true if value is asc variant"
  @spec is_asc(t()) :: boolean()
  def is_asc(:asc), do: true
  def is_asc(_), do: false

  @doc "Returns true if value is desc variant"
  @spec is_desc(t()) :: boolean()
  def is_desc(:desc), do: true
  def is_desc(_), do: false

end


defmodule TodoFilter do
  @moduledoc """
  TodoFilter enum generated from Haxe
  
  
 * Todo filter options
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :all |
    :active |
    :completed |
    {:by_tag, term()} |
    {:by_priority, term()} |
    {:by_due_date, term()}

  @doc "Creates all enum value"
  @spec all() :: :all
  def all(), do: :all

  @doc "Creates active enum value"
  @spec active() :: :active
  def active(), do: :active

  @doc "Creates completed enum value"
  @spec completed() :: :completed
  def completed(), do: :completed

  @doc """
  Creates by_tag enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec by_tag(term()) :: {:by_tag, term()}
  def by_tag(arg0) do
    {:by_tag, arg0}
  end

  @doc """
  Creates by_priority enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec by_priority(term()) :: {:by_priority, term()}
  def by_priority(arg0) do
    {:by_priority, arg0}
  end

  @doc """
  Creates by_due_date enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec by_due_date(term()) :: {:by_due_date, term()}
  def by_due_date(arg0) do
    {:by_due_date, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is all variant"
  @spec is_all(t()) :: boolean()
  def is_all(:all), do: true
  def is_all(_), do: false

  @doc "Returns true if value is active variant"
  @spec is_active(t()) :: boolean()
  def is_active(:active), do: true
  def is_active(_), do: false

  @doc "Returns true if value is completed variant"
  @spec is_completed(t()) :: boolean()
  def is_completed(:completed), do: true
  def is_completed(_), do: false

  @doc "Returns true if value is by_tag variant"
  @spec is_by_tag(t()) :: boolean()
  def is_by_tag({:by_tag, _}), do: true
  def is_by_tag(_), do: false

  @doc "Returns true if value is by_priority variant"
  @spec is_by_priority(t()) :: boolean()
  def is_by_priority({:by_priority, _}), do: true
  def is_by_priority(_), do: false

  @doc "Returns true if value is by_due_date variant"
  @spec is_by_due_date(t()) :: boolean()
  def is_by_due_date({:by_due_date, _}), do: true
  def is_by_due_date(_), do: false

  @doc "Extracts value from by_tag variant, returns {:ok, value} or :error"
  @spec get_by_tag_value(t()) :: {:ok, term()} | :error
  def get_by_tag_value({:by_tag, value}), do: {:ok, value}
  def get_by_tag_value(_), do: :error

  @doc "Extracts value from by_priority variant, returns {:ok, value} or :error"
  @spec get_by_priority_value(t()) :: {:ok, term()} | :error
  def get_by_priority_value({:by_priority, value}), do: {:ok, value}
  def get_by_priority_value(_), do: :error

  @doc "Extracts value from by_due_date variant, returns {:ok, value} or :error"
  @spec get_by_due_date_value(t()) :: {:ok, term()} | :error
  def get_by_due_date_value({:by_due_date, value}), do: {:ok, value}
  def get_by_due_date_value(_), do: :error

end


defmodule TodoSort do
  @moduledoc """
  TodoSort enum generated from Haxe
  
  
 * Todo sort options
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :created |
    :priority |
    :due_date |
    :title |
    :status

  @doc "Creates created enum value"
  @spec created() :: :created
  def created(), do: :created

  @doc "Creates priority enum value"
  @spec priority() :: :priority
  def priority(), do: :priority

  @doc "Creates due_date enum value"
  @spec due_date() :: :due_date
  def due_date(), do: :due_date

  @doc "Creates title enum value"
  @spec title() :: :title
  def title(), do: :title

  @doc "Creates status enum value"
  @spec status() :: :status
  def status(), do: :status

  # Predicate functions for pattern matching
  @doc "Returns true if value is created variant"
  @spec is_created(t()) :: boolean()
  def is_created(:created), do: true
  def is_created(_), do: false

  @doc "Returns true if value is priority variant"
  @spec is_priority(t()) :: boolean()
  def is_priority(:priority), do: true
  def is_priority(_), do: false

  @doc "Returns true if value is due_date variant"
  @spec is_due_date(t()) :: boolean()
  def is_due_date(:due_date), do: true
  def is_due_date(_), do: false

  @doc "Returns true if value is title variant"
  @spec is_title(t()) :: boolean()
  def is_title(:title), do: true
  def is_title(_), do: false

  @doc "Returns true if value is status variant"
  @spec is_status(t()) :: boolean()
  def is_status(:status), do: true
  def is_status(_), do: false

end


defmodule TodoPriority do
  @moduledoc """
  TodoPriority enum generated from Haxe
  
  
 * Todo priority levels
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :low |
    :medium |
    :high

  @doc "Creates low enum value"
  @spec low() :: :low
  def low(), do: :low

  @doc "Creates medium enum value"
  @spec medium() :: :medium
  def medium(), do: :medium

  @doc "Creates high enum value"
  @spec high() :: :high
  def high(), do: :high

  # Predicate functions for pattern matching
  @doc "Returns true if value is low variant"
  @spec is_low(t()) :: boolean()
  def is_low(:low), do: true
  def is_low(_), do: false

  @doc "Returns true if value is medium variant"
  @spec is_medium(t()) :: boolean()
  def is_medium(:medium), do: true
  def is_medium(_), do: false

  @doc "Returns true if value is high variant"
  @spec is_high(t()) :: boolean()
  def is_high(:high), do: true
  def is_high(_), do: false

end


defmodule BulkOperation do
  @moduledoc """
  BulkOperation enum generated from Haxe
  
  
 * Bulk operation types
 
  
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
