defmodule NotificationService do
  use Bitwise
  @moduledoc """
  NotificationService module generated from Haxe
  
  
 * Notification service demonstrating advanced Option<T> and Result<T,E> patterns.
 * 
 * This service shows real-world business logic that combines Option and Result types
 * for robust error handling and null safety in notification operations.
 * 
 * Key patterns demonstrated:
 * - Option<T> and Result<T,E> composition in business logic
 * - Safe service integration with external dependencies
 * - Error accumulation and validation chains
 * - Type-safe notification preferences and delivery
 
  """

  # Static functions
  @doc """
    Send a notification to a user by ID.

    Demonstrates chaining Option and Result operations for complex business logic.

    @param userId Target user ID
    @param message Notification message
    @param type Type of notification (email, sms, push)
    @return Ok(record) if sent successfully, Error(reason) if failed
  """
  @spec send_to_user(integer(), String.t(), NotificationType.t()) :: Result.t()
  def send_to_user(user_id, message, type) do
    if (message == nil || String.length(message) == 0), do: {:error, "Message cannot be empty"}, else: nil
    ResultTools.flatMap(ResultTools.flatMap(ResultTools.flatMap(OptionTools.toResult(UserRepository.find(user_id), "User not found"), fn user -> temp_result = nil
    if (!user.active), do: {:error, "Cannot send notifications to inactive users"}, else: nil
    {:ok, user}
    temp_result end), fn user -> NotificationService.checkUserPreferences(user.id, type) end), fn user -> NotificationService.deliverNotification(user, message, type) end)
  end

  @doc """
    Send a notification to a user by email address.

    Shows email-based lookup with Option/Result integration.

    @param email Target email address
    @param message Notification message
    @param type Type of notification
    @return Ok(record) if sent successfully, Error(reason) if failed
  """
  @spec send_to_email(String.t(), String.t(), NotificationType.t()) :: Result.t()
  def send_to_email(email, message, type) do
    ResultTools.flatMap(OptionTools.toResult(UserRepository.findByEmail(email), "No user found with email: " <> email), fn user -> NotificationService.sendToUser(user.id, message, type) end)
  end

  @doc """
    Get user notification preferences safely.

    Demonstrates Option return for nullable preference data.

    @param userId User ID
    @return Some(preferences) if set, None if not configured
  """
  @spec get_user_preferences(integer()) :: Option.t()
  def get_user_preferences(user_id) do
    this = NotificationService.preferences
    temp_maybe_notification_preferences = this.get(user_id)
    prefs = temp_maybe_notification_preferences
    temp_result = nil
    if (prefs != nil), do: temp_result = {:some, prefs}, else: temp_result = :none
    temp_result
  end

  @doc """
    Check if user allows a specific notification type.

    Shows Option chaining with boolean logic and defaults.

    @param userId User ID
    @param type Notification type to check
    @return True if allowed (or no preferences set), false if explicitly disabled
  """
  @spec is_notification_allowed(integer(), NotificationType.t()) :: boolean()
  def is_notification_allowed(user_id, type) do
    OptionTools.unwrap(Enum.map(OptionTools, NotificationService.getUserPreferences(user_id)), true)
  end

  @doc """
    Bulk send notifications to multiple users.

    Demonstrates processing arrays with Option/Result accumulation.

    @param userIds Array of user IDs
    @param message Notification message
    @param type Notification type
    @return Result with success count and failure details
  """
  @spec send_bulk(Array.t(), String.t(), NotificationType.t()) :: BulkNotificationResult.t()
  def send_bulk(user_ids, message, type) do
    successful = []
    failed = []
    _g = 0
    Enum.map(user_ids, fn item -> item end)
    Services.BulkNotificationResult.new(successful, failed)
  end

  @doc """
    Get notification history for a user.

    Shows filtering with Option integration.

    @param userId User ID
    @return Array of notification records for the user
  """
  @spec get_user_notification_history(integer()) :: Array.t()
  def get_user_notification_history(user_id) do
    result = []
    _g = 0
    _g = NotificationService.delivery_log
    Enum.filter(_g, fn item -> (record.userId == item) end)
    result
  end

  @doc """
    Get the most recent notification for a user.

    Demonstrates Option return for potentially missing data.

    @param userId User ID
    @return Some(record) if user has notifications, None otherwise
  """
  @spec get_most_recent_notification(integer()) :: Option.t()
  def get_most_recent_notification(user_id) do
    user_notifications = NotificationService.getUserNotificationHistory(user_id)
    if (length(user_notifications) == 0), do: :none, else: nil
    most_recent = Enum.at(user_notifications, 0)
    _g = 1
    _g = length(user_notifications)
    (
      try do
        loop_fn = fn {mostRecent} ->
          if (_g < _g) do
            try do
              i = _g = _g + 1
          if (Enum.at(user_notifications, i).timestamp > most_recent.timestamp), do: most_recent = Enum.at(user_notifications, i), else: nil
          loop_fn.({mostRecent})
            catch
              :break -> {mostRecent}
              :continue -> loop_fn.({mostRecent})
            end
          else
            {mostRecent}
          end
        end
        loop_fn.({mostRecent})
      catch
        :break -> {mostRecent}
      end
    )
    {:some, most_recent}
  end

  @doc """
    Set user notification preferences.

    Shows Result return for operations that can fail validation.

    @param userId User ID
    @param emailEnabled Whether email notifications are enabled
    @param smsEnabled Whether SMS notifications are enabled
    @param pushEnabled Whether push notifications are enabled
    @return Ok(preferences) if set successfully, Error(reason) if failed
  """
  @spec set_user_preferences(integer(), boolean(), boolean(), boolean()) :: Result.t()
  def set_user_preferences(user_id, email_enabled, sms_enabled, push_enabled) do
    Enum.map(ResultTools, OptionTools.toResult(UserRepository.find(user_id), "User not found"))
  end

  @doc """
    Check user preferences for notification type.

    Internal helper showing Option/Result integration.
  """
  @spec check_user_preferences(integer(), NotificationType.t()) :: Result.t()
  def check_user_preferences(user_id, type) do
    if (!NotificationService.isNotificationAllowed(user_id, type)), do: {:error, "User has disabled " <> Std.string(type) <> " notifications"}, else: nil
    OptionTools.toResult(UserRepository.find(user_id), "User not found during preference check")
  end

  @doc """
    Actually deliver the notification.

    Simulates external service integration with error handling.
  """
  @spec deliver_notification(User.t(), String.t(), NotificationType.t()) :: Result.t()
  def deliver_notification(user, message, type) do
    if (!user.hasValidEmail() && type == :email), do: {:error, "User has invalid email address"}, else: nil
    if (case :binary.match(message, "FAIL") do {pos, _} -> pos; :nomatch -> -1 end >= 0), do: {:error, "Simulated delivery failure"}, else: nil
    record = Services.NotificationRecord.new(user.id, message, type, Sys.time(), true)
    NotificationService.delivery_log ++ [record]
    {:ok, record}
  end

end


defmodule NotificationPreferences do
  use Bitwise
  @moduledoc """
  NotificationPreferences module generated from Haxe
  
  
 * Notification preferences data structure.
 
  """

  # Instance functions
  @doc "Function is_allowed"
  @spec is_allowed(NotificationType.t()) :: boolean()
  def is_allowed(type) do
    temp_result = nil
    case (elem(type, 0)) do
      0 ->
        temp_result = __MODULE__.email_enabled
      1 ->
        temp_result = __MODULE__.sms_enabled
      2 ->
        temp_result = __MODULE__.push_enabled
    end
    temp_result
  end

end


defmodule NotificationRecord do
  use Bitwise
  @moduledoc """
  NotificationRecord module generated from Haxe
  
  
 * Notification delivery record.
 
  """

end


defmodule BulkNotificationResult do
  use Bitwise
  @moduledoc """
  BulkNotificationResult module generated from Haxe
  
  
 * Bulk notification result containing success and failure information.
 
  """

  # Instance functions
  @doc "Function get_success_count"
  @spec get_success_count() :: integer()
  def get_success_count() do
    length(__MODULE__.successful)
  end

  @doc "Function get_failure_count"
  @spec get_failure_count() :: integer()
  def get_failure_count() do
    length(__MODULE__.failed)
  end

  @doc "Function get_total_count"
  @spec get_total_count() :: integer()
  def get_total_count() do
    __MODULE__.getSuccessCount() + __MODULE__.getFailureCount()
  end

  @doc "Function get_success_rate"
  @spec get_success_rate() :: float()
  def get_success_rate() do
    total = __MODULE__.getTotalCount()
    temp_result = nil
    if (total > 0), do: temp_result = __MODULE__.getSuccessCount() / total, else: temp_result = 0.0
    temp_result
  end

end


defmodule NotificationType do
  @moduledoc """
  NotificationType enum generated from Haxe
  
  
 * Types of notifications supported.
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :email |
    :s_m_s |
    :push

  @doc "Creates email enum value"
  @spec email() :: :email
  def email(), do: :email

  @doc "Creates s_m_s enum value"
  @spec s_m_s() :: :s_m_s
  def s_m_s(), do: :s_m_s

  @doc "Creates push enum value"
  @spec push() :: :push
  def push(), do: :push

  # Predicate functions for pattern matching
  @doc "Returns true if value is email variant"
  @spec is_email(t()) :: boolean()
  def is_email(:email), do: true
  def is_email(_), do: false

  @doc "Returns true if value is s_m_s variant"
  @spec is_s_m_s(t()) :: boolean()
  def is_s_m_s(:s_m_s), do: true
  def is_s_m_s(_), do: false

  @doc "Returns true if value is push variant"
  @spec is_push(t()) :: boolean()
  def is_push(:push), do: true
  def is_push(_), do: false

end
