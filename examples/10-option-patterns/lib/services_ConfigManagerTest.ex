defmodule ConfigManagerTest do
  use ExUnit.Case

  @moduledoc """
  
 * ExUnit tests for ConfigManager demonstrating Option<T> configuration patterns.
 * 
 * These tests verify that configuration management correctly handles missing values,
 * invalid formats, and provides appropriate defaults and validation.
 
  """

  test "get returns value for existing key" do
    value = ConfigManager.get("app_name")
    assert OptionTools.is_some(value)
    assert "OptionPatterns"} == {:some
  end

  test "get returns none for missing key" do
    value = ConfigManager.get("nonexistent_key")
    assert OptionTools.is_none(value)
  end

  test "get returns none for empty value" do
    value = ConfigManager.get("empty_value")
    assert OptionTools.is_none(value)
  end

  test "get returns none for null key" do
    value = ConfigManager.get(nil)
    assert OptionTools.is_none(value)
  end

  test "get returns none for empty key" do
    value = ConfigManager.get("")
    assert OptionTools.is_none(value)
  end

  test "get with default returns value for existing key" do
    value = ConfigManager.getWithDefault("app_name", "DefaultApp")
    assert value == "OptionPatterns"
  end

  test "get with default returns default for missing key" do
    value = ConfigManager.getWithDefault("missing_key", "DefaultValue")
    assert value == "DefaultValue"
  end

  test "get required returns ok for existing key" do
    result = ConfigManager.getRequired("app_name")
    assert ResultTools.is_ok(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    value = _g
    assert value == "OptionPatterns"
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    flunk("Unexpected error: " <> msg)
    end
  end

  test "get required returns error for missing key" do
    result = ConfigManager.getRequired("missing_key")
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for missing required key")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert case :binary.match(msg do {pos, _} -> pos; :nomatch -> -1 end >= 0, "Error should mention the missing key")
    end
  end

  test "get int returns value for valid number" do
    value = ConfigManager.getInt("timeout")
    assert OptionTools.is_some(value)
    assert 30} == {:some
  end

  test "get int returns none for invalid number" do
    value = ConfigManager.getInt("invalid_number")
    assert OptionTools.is_none(value)
  end

  test "get int returns none for missing key" do
    value = ConfigManager.getInt("missing_key")
    assert OptionTools.is_none(value)
  end

  test "get bool returns true for valid true values" do
    value = ConfigManager.getBool("debug")
    assert OptionTools.is_some(value)
    assert true} == {:some
  end

  test "get bool returns none for invalid value" do
    value = ConfigManager.getBool("app_name")
    assert OptionTools.is_none(value)
  end

  test "get bool returns none for missing key" do
    value = ConfigManager.getBool("missing_key")
    assert OptionTools.is_none(value)
  end

  test "get int with range succeeds for valid value" do
    result = ConfigManager.getIntWithRange("max_connections", 1, 1000)
    assert ResultTools.is_ok(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    value = _g
    assert value == 100
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    flunk("Unexpected error: " <> msg)
    end
  end

  test "get int with range fails for value below min" do
    result = ConfigManager.getIntWithRange("timeout", 100, 1000)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for value below minimum")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert case :binary.match(msg do {pos, _} -> pos; :nomatch -> -1 end >= 0, "Error should mention minimum value")
    end
  end

  test "get int with range fails for value above max" do
    result = ConfigManager.getIntWithRange("max_connections", 1, 50)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for value above maximum")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert case :binary.match(msg do {pos, _} -> pos; :nomatch -> -1 end >= 0, "Error should mention maximum value")
    end
  end

  test "get int with range fails for missing key" do
    result = ConfigManager.getIntWithRange("missing_key", 1, 100)
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for missing key")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert case :binary.match(msg do {pos, _} -> pos; :nomatch -> -1 end >= 0, "Error should mention missing/invalid")
    end
  end

  test "get database url succeeds for valid url" do
    result = ConfigManager.getDatabaseUrl()
    assert ResultTools.is_ok(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    url = _g
    assert case :binary.match(url do {pos, _} -> pos; :nomatch -> -1 end >= 0, "Should contain protocol")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    flunk("Unexpected error: " <> msg)
    end
  end

  test "get timeout returns valid value within bounds" do
    timeout = ConfigManager.getTimeout()
    assert timeout >= 1 && timeout <= 300
    assert timeout == 30
  end

  test "is debug enabled returns correct value" do
    debug_enabled = ConfigManager.isDebugEnabled()
    assert debug_enabled
  end

  test "get all set values returns only non empty values" do
    all_values = ConfigManager.getAllSetValues()
    assert all_values.exists("app_name", "Should include app_name")
    assert all_values.exists("timeout", "Should include timeout")
    refute all_values.exists("empty_value", "Should not include empty values")
    key = all_values.keys()
    (
      try do
        loop_fn = fn ->
          if (key.hasNext()) do
            try do
              key = key.next()
    value = all_values.get(key)
    assert value != nil && value != ""
              loop_fn.()
            catch
              :break -> nil
              :continue -> loop_fn.()
            end
          end
        end
        loop_fn.()
      catch
        :break -> nil
      end
    )
  end

  test "validate required succeeds when all keys present" do
    result = ConfigManager.validateRequired(["app_name", "timeout", "debug"])
    assert ResultTools.is_ok(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    valid = _g
    assert valid
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    flunk("Unexpected error: " <> msg)
    end
  end

  test "validate required fails when keys are missing" do
    result = ConfigManager.validateRequired(["app_name", "missing_key1", "missing_key2"])
    assert ResultTools.is_error(result)
    case (case result do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
      0 ->
        case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    flunk("Expected error for missing required keys")
      1 ->
        _g = case result do {:ok, value} -> value; {:error, value} -> value; _ -> nil end
    msg = _g
    assert case :binary.match(msg do {pos, _} -> pos; :nomatch -> -1 end >= 0, "Error should mention first missing key")
    assert case :binary.match(msg do {pos, _} -> pos; :nomatch -> -1 end >= 0, "Error should mention second missing key")
    end
  end

  test "validate required succeeds for empty array" do
    result = ConfigManager.validateRequired([])
    assert ResultTools.is_ok(result)
  end

end
