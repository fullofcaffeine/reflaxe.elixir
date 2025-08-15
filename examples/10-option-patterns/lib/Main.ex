defmodule Main do
  use Bitwise
  @moduledoc """
  Main module generated from Haxe
  
  
 * Main demonstration of Option<T> patterns in real-world scenarios.
 * 
 * This class showcases how Option<T> and Result<T,E> types work together
 * to create robust, type-safe applications that eliminate null pointer exceptions.
 
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("=== Option<T> Patterns Demo ===\n", %{fileName: "src_haxe/Main.hx", lineNumber: 20, className: "Main", methodName: "main"})
    Main.demonstrateRepositoryPatterns()
    Main.demonstrateConfigurationManagement()
    Main.demonstrateNotificationService()
    Main.demonstrateErrorHandling()
    Main.demonstrateFunctionalComposition()
    Log.trace("\n=== Demo Complete ===", %{fileName: "src_haxe/Main.hx", lineNumber: 28, className: "Main", methodName: "main"})
    Log.trace("All operations completed without null pointer exceptions!", %{fileName: "src_haxe/Main.hx", lineNumber: 29, className: "Main", methodName: "main"})
  end

  @doc "Demonstrate safe repository access "
  @spec demonstrate_repository_patterns() :: nil
  def demonstrate_repository_patterns() do
    Log.trace("1. Repository Patterns with Option<T>", %{fileName: "src_haxe/Main.hx", lineNumber: 36, className: "Main", methodName: "demonstrateRepositoryPatterns"})
    Log.trace("=====================================", %{fileName: "src_haxe/Main.hx", lineNumber: 37, className: "Main", methodName: "demonstrateRepositoryPatterns"})
    user = UserRepository.find(1)
    case (case user do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case user do {:some, value} -> value; :none -> nil; _ -> nil end
    u = _g
    Log.trace("Found user: " <> u.getDisplayName(), %{fileName: "src_haxe/Main.hx", lineNumber: 42, className: "Main", methodName: "demonstrateRepositoryPatterns"})
      1 ->
        Log.trace("User not found", %{fileName: "src_haxe/Main.hx", lineNumber: 43, className: "Main", methodName: "demonstrateRepositoryPatterns"})
    end
    email_display = OptionTools.unwrap(Enum.map(OptionTools, Enum.map(OptionTools, UserRepository.find(2))), "No email available")
    Log.trace(email_display, %{fileName: "src_haxe/Main.hx", lineNumber: 51, className: "Main", methodName: "demonstrateRepositoryPatterns"})
    display_name = UserRepository.getUserDisplayName(999)
    Log.trace("Display name: " <> display_name, %{fileName: "src_haxe/Main.hx", lineNumber: 55, className: "Main", methodName: "demonstrateRepositoryPatterns"})
    is_active = UserRepository.isUserActive(3)
    Log.trace("User 3 is active: " <> Std.string(is_active), %{fileName: "src_haxe/Main.hx", lineNumber: 59, className: "Main", methodName: "demonstrateRepositoryPatterns"})
    Log.trace("", %{fileName: "src_haxe/Main.hx", lineNumber: 61, className: "Main", methodName: "demonstrateRepositoryPatterns"})
  end

  @doc "Demonstrate configuration management with defaults and "
  @spec demonstrate_configuration_management() :: nil
  def demonstrate_configuration_management() do
    Log.trace("2. Configuration Management", %{fileName: "src_haxe/Main.hx", lineNumber: 68, className: "Main", methodName: "demonstrateConfigurationManagement"})
    Log.trace("===========================", %{fileName: "src_haxe/Main.hx", lineNumber: 69, className: "Main", methodName: "demonstrateConfigurationManagement"})
    app_name = ConfigManager.getWithDefault("app_name", "DefaultApp")
    Log.trace("App name: " <> app_name, %{fileName: "src_haxe/Main.hx", lineNumber: 73, className: "Main", methodName: "demonstrateConfigurationManagement"})
    timeout = OptionTools.unwrap(ConfigManager.getInt("timeout"), 30)
    Log.trace("Timeout: " <> Integer.to_string(timeout) <> "s", %{fileName: "src_haxe/Main.hx", lineNumber: 77, className: "Main", methodName: "demonstrateConfigurationManagement"})
    debug_mode = ConfigManager.isDebugEnabled()
    Log.trace("Debug mode: " <> Std.string(debug_mode), %{fileName: "src_haxe/Main.hx", lineNumber: 81, className: "Main", methodName: "demonstrateConfigurationManagement"})
    _g = ConfigManager.getIntWithRange("max_connections", 1, 1000)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    value = _g
    Log.trace("Max connections: " <> Integer.to_string(value), %{fileName: "src_haxe/Main.hx", lineNumber: 85, className: "Main", methodName: "demonstrateConfigurationManagement"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    Log.trace("Config error: " <> msg, %{fileName: "src_haxe/Main.hx", lineNumber: 86, className: "Main", methodName: "demonstrateConfigurationManagement"})
    end
    _g = ConfigManager.getDatabaseUrl()
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    _g
    Log.trace("Database URL validated successfully", %{fileName: "src_haxe/Main.hx", lineNumber: 91, className: "Main", methodName: "demonstrateConfigurationManagement"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    Log.trace("Database config error: " <> msg, %{fileName: "src_haxe/Main.hx", lineNumber: 92, className: "Main", methodName: "demonstrateConfigurationManagement"})
    end
    Log.trace("", %{fileName: "src_haxe/Main.hx", lineNumber: 95, className: "Main", methodName: "demonstrateConfigurationManagement"})
  end

  @doc "Demonstrate notification service with complex business "
  @spec demonstrate_notification_service() :: nil
  def demonstrate_notification_service() do
    Log.trace("3. Notification Service Integration", %{fileName: "src_haxe/Main.hx", lineNumber: 102, className: "Main", methodName: "demonstrateNotificationService"})
    Log.trace("==================================", %{fileName: "src_haxe/Main.hx", lineNumber: 103, className: "Main", methodName: "demonstrateNotificationService"})
    _g = NotificationService.sendToUser(1, "Welcome to our service!", :email)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    record = _g
    Log.trace("Notification sent successfully to user " <> Integer.to_string(record.user_id), %{fileName: "src_haxe/Main.hx", lineNumber: 107, className: "Main", methodName: "demonstrateNotificationService"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    reason = _g
    Log.trace("Failed to send notification: " <> reason, %{fileName: "src_haxe/Main.hx", lineNumber: 108, className: "Main", methodName: "demonstrateNotificationService"})
    end
    _g = NotificationService.sendToUser(3, "Test message", :email)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    _g
    Log.trace("Unexpected success", %{fileName: "src_haxe/Main.hx", lineNumber: 113, className: "Main", methodName: "demonstrateNotificationService"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    reason = _g
    Log.trace("Expected failure: " <> reason, %{fileName: "src_haxe/Main.hx", lineNumber: 114, className: "Main", methodName: "demonstrateNotificationService"})
    end
    _g = NotificationService.sendToEmail("alice@example.com", "Email notification", :email)
    case (case _g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    _g
    Log.trace("Email notification sent successfully", %{fileName: "src_haxe/Main.hx", lineNumber: 119, className: "Main", methodName: "demonstrateNotificationService"})
      1 ->
        _g = case _g do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    reason = _g
    Log.trace("Email send failed: " <> reason, %{fileName: "src_haxe/Main.hx", lineNumber: 120, className: "Main", methodName: "demonstrateNotificationService"})
    end
    prefs_allowed = NotificationService.isNotificationAllowed(1, :push)
    Log.trace("User 1 allows push notifications: " <> Std.string(prefs_allowed), %{fileName: "src_haxe/Main.hx", lineNumber: 125, className: "Main", methodName: "demonstrateNotificationService"})
    bulk_result = NotificationService.sendBulk([1, 2, 3, 4], "Bulk message", :email)
    Log.trace("Bulk send: " <> Integer.to_string(bulk_result.getSuccessCount()) <> "/" <> Integer.to_string(bulk_result.getTotalCount()) <> " successful", %{fileName: "src_haxe/Main.hx", lineNumber: 129, className: "Main", methodName: "demonstrateNotificationService"})
    Log.trace("", %{fileName: "src_haxe/Main.hx", lineNumber: 131, className: "Main", methodName: "demonstrateNotificationService"})
  end

  @doc "Demonstrate error handling patterns with Option and "
  @spec demonstrate_error_handling() :: nil
  def demonstrate_error_handling() do
    Log.trace("4. Error Handling Patterns", %{fileName: "src_haxe/Main.hx", lineNumber: 138, className: "Main", methodName: "demonstrateErrorHandling"})
    Log.trace("==========================", %{fileName: "src_haxe/Main.hx", lineNumber: 139, className: "Main", methodName: "demonstrateErrorHandling"})
    user_result = ResultTools.flatMap(OptionTools.toResult(UserRepository.find(999), "User 999 not found"), fn user -> temp_result = nil
    if (!user.hasValidEmail()), do: {:error, "User has invalid email"}, else: nil
    {:ok, user}
    temp_result end)
    case (case user_result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case user_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    user = _g
    Log.trace("User validated: " <> user.email, %{fileName: "src_haxe/Main.hx", lineNumber: 152, className: "Main", methodName: "demonstrateErrorHandling"})
      1 ->
        _g = case user_result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    Log.trace("Validation failed: " <> msg, %{fileName: "src_haxe/Main.hx", lineNumber: 153, className: "Main", methodName: "demonstrateErrorHandling"})
    end
    create_result = UserRepository.create("New User", "new@example.com")
    user_option = ResultTools.toOption(create_result)
    case (case user_option do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case user_option do {:some, value} -> value; :none -> nil; _ -> nil end
    user = _g
    Log.trace("Created user: " <> user.name, %{fileName: "src_haxe/Main.hx", lineNumber: 160, className: "Main", methodName: "demonstrateErrorHandling"})
      1 ->
        Log.trace("User creation failed", %{fileName: "src_haxe/Main.hx", lineNumber: 161, className: "Main", methodName: "demonstrateErrorHandling"})
    end
    validation_chain = ResultTools.flatMap(ResultTools.flatMap(ConfigManager.getRequired("timeout"), fn timeout_str -> temp_result1 = nil
    timeout = Std.parseInt(timeout_str)
    temp_result2 = nil
    if (timeout != nil), do: temp_result2 = {:ok, timeout}, else: temp_result2 = {:error, "Invalid timeout format"}
    temp_result2
    temp_result1 end), fn timeout -> temp_result3 = nil
    if (timeout < 1 || timeout > 300), do: {:error, "Timeout must be between 1 and 300 seconds"}, else: nil
    {:ok, timeout}
    temp_result3 end)
    case (case validation_chain do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case validation_chain do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    timeout = _g
    Log.trace("Validated timeout: " <> Kernel.inspect(timeout) <> "s", %{fileName: "src_haxe/Main.hx", lineNumber: 178, className: "Main", methodName: "demonstrateErrorHandling"})
      1 ->
        _g = case validation_chain do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    Log.trace("Validation error: " <> msg, %{fileName: "src_haxe/Main.hx", lineNumber: 179, className: "Main", methodName: "demonstrateErrorHandling"})
    end
    Log.trace("", %{fileName: "src_haxe/Main.hx", lineNumber: 182, className: "Main", methodName: "demonstrateErrorHandling"})
  end

  @doc "Demonstrate functional composition "
  @spec demonstrate_functional_composition() :: nil
  def demonstrate_functional_composition() do
    Log.trace("5. Functional Composition", %{fileName: "src_haxe/Main.hx", lineNumber: 189, className: "Main", methodName: "demonstrateFunctionalComposition"})
    Log.trace("=========================", %{fileName: "src_haxe/Main.hx", lineNumber: 190, className: "Main", methodName: "demonstrateFunctionalComposition"})
    temp_option = nil
    temp_option1 = nil
    option = UserRepository.find(1)
    temp_option1 = OptionTools.then(option, fn user -> temp_result = nil
    if (user.active), do: temp_result = {:some, user}, else: temp_result = :none
    temp_result end)
    option = Enum.map(OptionTools, temp_option1)
    temp_option = OptionTools.then(option, fn email -> temp_result1 = nil
    if (case :binary.match(email, "@") do {pos, _} -> pos; :nomatch -> -1 end > 0), do: temp_result1 = {:some, email}, else: temp_result1 = :none
    temp_result1 end)
    composed_operation = Enum.map(OptionTools, temp_option)
    case (case composed_operation do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case composed_operation do {:some, value} -> value; :none -> nil; _ -> nil end
    result = _g
    Log.trace("Composed result: " <> result, %{fileName: "src_haxe/Main.hx", lineNumber: 206, className: "Main", methodName: "demonstrateFunctionalComposition"})
      1 ->
        Log.trace("Composition chain failed at some point", %{fileName: "src_haxe/Main.hx", lineNumber: 207, className: "Main", methodName: "demonstrateFunctionalComposition"})
    end
    user_ids = [1, 2, 999, 4]
    valid_users = []
    _g = 0
    Enum.map(user_ids, fn item -> item end)
    Log.trace("Found " <> Integer.to_string(length(valid_users)) <> "/" <> Integer.to_string(length(user_ids)) <> " valid users", %{fileName: "src_haxe/Main.hx", lineNumber: 221, className: "Main", methodName: "demonstrateFunctionalComposition"})
    user_emails = []
    _g = 0
    Enum.map(user_ids, fn item -> item end)
    Log.trace("User emails: " <> Enum.join(user_emails, ", "), %{fileName: "src_haxe/Main.hx", lineNumber: 233, className: "Main", methodName: "demonstrateFunctionalComposition"})
    active_user_names = []
    _g = 0
    Enum.map(user_ids, fn item -> OptionTools.map(OptionTools.filter(UserRepository.find(id), fn user -> user.active end), fn user -> user.name end) end)
    Log.trace("Active user names: " <> Enum.join(active_user_names, ", "), %{fileName: "src_haxe/Main.hx", lineNumber: 244, className: "Main", methodName: "demonstrateFunctionalComposition"})
    Log.trace("", %{fileName: "src_haxe/Main.hx", lineNumber: 246, className: "Main", methodName: "demonstrateFunctionalComposition"})
  end

end
