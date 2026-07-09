defmodule OptionPatterns.ConfigManagerTest do
  use ExUnit.Case
  test "get returns value for existing key" do
    value = OptionPatterns.ConfigManager.get("app_name")
    _ = assert(match?({:some, _}, value), "Should find existing configuration key")
    _ = assert({:some, "OptionPatterns"} == value, "Should have correct value")
  end
  test "get returns none for missing key" do
    value = OptionPatterns.ConfigManager.get("nonexistent_key")
    _ = assert(match?({:none}, value), "Should not find missing configuration key")
  end
  test "get returns none for empty value" do
    value = OptionPatterns.ConfigManager.get("empty_value")
    _ = assert(match?({:none}, value), "Should return None for empty configuration value")
  end
  test "get returns none for null key" do
    value = OptionPatterns.ConfigManager.get(nil)
    _ = assert(match?({:none}, value), "Should return None for null key")
  end
  test "get returns none for empty key" do
    value = OptionPatterns.ConfigManager.get("")
    _ = assert(match?({:none}, value), "Should return None for empty key")
  end
  test "get with default returns value for existing key" do
    value = OptionPatterns.ConfigManager.get_with_default("app_name", "DefaultApp")
    _ = assert("OptionPatterns" == value, "Should return existing value")
  end
  test "get with default returns default for missing key" do
    value = OptionPatterns.ConfigManager.get_with_default("missing_key", "DefaultValue")
    _ = assert("DefaultValue" == value, "Should return default value for missing key")
  end
  test "get required returns ok for existing key" do
    result = OptionPatterns.ConfigManager.get_required("app_name")
    _ = assert(match?({:ok, _}, result), "Should successfully get required configuration")
    (case result do
      {:ok, value} ->
        assert("OptionPatterns" == value, "Should have correct value")
      {:error, msg} ->
        flunk("Unexpected error: " <> msg)
    end)
  end
  test "get required returns error for missing key" do
    result = OptionPatterns.ConfigManager.get_required("missing_key")
    _ = assert(match?({:error, _}, result), "Should fail for missing required configuration")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for missing required key")
      {:error, msg} ->
        assert(StringTools.haxe_index_of(msg, "missing_key", 0) >= 0, "Error should mention the missing key")
    end)
  end
  test "get int returns value for valid number" do
    value = OptionPatterns.ConfigManager.get_int("timeout")
    _ = assert(match?({:some, _}, value), "Should parse valid integer")
    _ = assert({:some, 30} == value, "Should have correct integer value")
  end
  test "get int returns none for invalid number" do
    value = OptionPatterns.ConfigManager.get_int("invalid_number")
    _ = assert(match?({:none}, value), "Should return None for invalid number")
  end
  test "get int returns none for missing key" do
    value = OptionPatterns.ConfigManager.get_int("missing_key")
    _ = assert(match?({:none}, value), "Should return None for missing key")
  end
  test "get bool returns true for valid true values" do
    value = OptionPatterns.ConfigManager.get_bool("debug")
    _ = assert(match?({:some, _}, value), "Should parse valid boolean")
    _ = assert({:some, true} == value, "Should parse 'true' as true")
  end
  test "get bool returns none for invalid value" do
    value = OptionPatterns.ConfigManager.get_bool("app_name")
    _ = assert(match?({:none}, value), "Should return None for non-boolean value")
  end
  test "get bool returns none for missing key" do
    value = OptionPatterns.ConfigManager.get_bool("missing_key")
    _ = assert(match?({:none}, value), "Should return None for missing key")
  end
  test "get int with range succeeds for valid value" do
    result = OptionPatterns.ConfigManager.get_int_with_range("max_connections", 1, 1000)
    _ = assert(match?({:ok, _}, result), "Should succeed for value within range")
    (case result do
      {:ok, value} ->
        assert(100 == value, "Should have correct value")
      {:error, msg} ->
        flunk("Unexpected error: " <> msg)
    end)
  end
  test "get int with range fails for value below min" do
    result = OptionPatterns.ConfigManager.get_int_with_range("timeout", 100, 1000)
    _ = assert(match?({:error, _}, result), "Should fail for value below minimum")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for value below minimum")
      {:error, msg} ->
        assert(StringTools.haxe_index_of(msg, "below minimum", 0) >= 0, "Error should mention minimum value")
    end)
  end
  test "get int with range fails for value above max" do
    result = OptionPatterns.ConfigManager.get_int_with_range("max_connections", 1, 50)
    _ = assert(match?({:error, _}, result), "Should fail for value above maximum")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for value above maximum")
      {:error, msg} ->
        assert(StringTools.haxe_index_of(msg, "above maximum", 0) >= 0, "Error should mention maximum value")
    end)
  end
  test "get int with range fails for missing key" do
    result = OptionPatterns.ConfigManager.get_int_with_range("missing_key", 1, 100)
    _ = assert(match?({:error, _}, result), "Should fail for missing key")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for missing key")
      {:error, msg} ->
        assert(StringTools.haxe_index_of(msg, "missing or not a valid number", 0) >= 0, "Error should mention missing/invalid")
    end)
  end
  test "get database url succeeds for valid url" do
    result = OptionPatterns.ConfigManager.get_database_url()
    _ = assert(match?({:ok, _}, result), "Should succeed for valid database URL")
    (case result do
      {:ok, url} ->
        assert(StringTools.haxe_index_of(url, "postgres://", 0) >= 0, "Should contain protocol")
      {:error, msg} ->
        flunk("Unexpected error: " <> msg)
    end)
  end
  test "get timeout returns valid value within bounds" do
    timeout = OptionPatterns.ConfigManager.get_timeout()
    _ = assert(timeout >= 1 and timeout <= 300, "Timeout should be within valid bounds")
    _ = assert(30 == timeout, "Should return configured timeout value")
  end
  test "is debug enabled returns correct value" do
    debug_enabled = OptionPatterns.ConfigManager.is_debug_enabled()
    _ = assert(debug_enabled, "Debug mode should be enabled in test config")
  end
  test "get all set values returns only non empty values" do
    all_values = OptionPatterns.ConfigManager.get_all_set_values()
    _ = assert(Map.has_key?(all_values, "app_name"), "Should include app_name")
    _ = assert(Map.has_key?(all_values, "timeout"), "Should include timeout")
    _ = refute(Map.has_key?(all_values, "empty_value"), "Should not include empty values")
    _ =
      Enum.reduce_while(Map.keys(all_values), :ok, fn key, acc ->
        try do
          value = Map.get(all_values, key)
          _ = assert(not Kernel.is_nil(value) and value != "", "Value for " <> key <> " should not be empty")
          {:cont, acc}
        catch
          :throw, {:break, break_state} ->
            {:halt, break_state}
          :throw, {:continue, continue_state} ->
            {:cont, continue_state}
          :throw, :break ->
            {:halt, acc}
          :throw, :continue ->
            {:cont, acc}
        end
      end)
  end
  test "validate required succeeds when all keys present" do
    result = OptionPatterns.ConfigManager.validate_required(["app_name", "timeout", "debug"])
    _ = assert(match?({:ok, _}, result), "Should succeed when all required keys are present")
    (case result do
      {:ok, valid} ->
        assert(valid, "Should return true for valid configuration")
      {:error, msg} ->
        flunk("Unexpected error: " <> msg)
    end)
  end
  test "validate required fails when keys are missing" do
    result = OptionPatterns.ConfigManager.validate_required(["app_name", "missing_key1", "missing_key2"])
    _ = assert(match?({:error, _}, result), "Should fail when required keys are missing")
    (case result do
      {:ok, _value} ->
        flunk("Expected error for missing required keys")
      {:error, msg} ->
        _ = assert(StringTools.haxe_index_of(msg, "missing_key1", 0) >= 0, "Error should mention first missing key")
        _ = assert(StringTools.haxe_index_of(msg, "missing_key2", 0) >= 0, "Error should mention second missing key")
    end)
  end
  test "validate required succeeds for empty array" do
    result = OptionPatterns.ConfigManager.validate_required([])
    _ = assert(match?({:ok, _}, result), "Should succeed for empty required keys array")
  end
end
