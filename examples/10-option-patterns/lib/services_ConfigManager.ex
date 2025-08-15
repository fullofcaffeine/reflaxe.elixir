defmodule ConfigManager do
  use Bitwise
  @moduledoc """
  ConfigManager module generated from Haxe
  
  
 * Configuration manager demonstrating Option<T> patterns for safe config access.
 * 
 * This service shows how to use Option<T> for configuration values that may not exist,
 * providing type-safe access with default values and validation.
 * 
 * Key patterns demonstrated:
 * - Option<T> for nullable configuration values
 * - Conversion between Option and Result for error handling
 * - Safe parsing of configuration with fallbacks
 * - Type-safe validation chains
 
  """

  # Static functions
  @doc """
    Get a configuration value as Option<String>.

    Returns None for missing or empty values, making the absence explicit.

    @param key Configuration key
    @return Some(value) if exists and non-empty, None otherwise
  """
  @spec get(String.t()) :: Option.t()
  def get(key) do
    if (key == nil || key == ""), do: :none, else: nil
    this = ConfigManager.config
    temp_maybe_string = this.get(key)
    if (temp_maybe_string == nil || temp_maybe_string == ""), do: :none, else: nil
    {:some, temp_maybe_string}
  end

  @doc """
    Get a configuration value with a default.

    Demonstrates using unwrap() to provide fallback values.

    @param key Configuration key
    @param defaultValue Default value if config is missing
    @return Configuration value or default
  """
  @spec get_with_default(String.t(), String.t()) :: String.t()
  def get_with_default(key, default_value) do
    OptionTools.unwrap(ConfigManager.get(key), default_value)
  end

  @doc """
    Get a required configuration value as Result.

    Converts Option to Result for error handling when a value is mandatory.

    @param key Configuration key
    @return Ok(value) if exists, Error(message) if missing
  """
  @spec get_required(String.t()) :: Result.t()
  def get_required(key) do
    OptionTools.toResult(ConfigManager.get(key), "Required configuration \"" <> key <> "\" is missing or empty")
  end

  @doc """
    Get configuration value as integer.

    Demonstrates safe parsing with Option return type.

    @param key Configuration key
    @return Some(number) if exists and valid, None otherwise
  """
  @spec get_int(String.t()) :: Option.t()
  def get_int(key) do
    option = ConfigManager.get(key)
    temp_result = OptionTools.then(option, fn value -> temp_result1 = nil
    parsed = Std.parseInt(value)
    temp_result2 = nil
    if (parsed != nil), do: temp_result2 = {:some, parsed}, else: temp_result2 = :none
    temp_result2
    temp_result1 end)
    temp_result
  end

  @doc """
    Get configuration value as boolean.

    Demonstrates custom parsing logic with Option chaining.

    @param key Configuration key
    @return Some(boolean) if exists and valid, None otherwise
  """
  @spec get_bool(String.t()) :: Option.t()
  def get_bool(key) do
    option = ConfigManager.get(key)
    temp_result = OptionTools.then(option, fn value -> temp_result1 = nil
    _g = String.downcase(value)
    case (_g) do
      "0" ->
        temp_result1 = {:some, false}
      "false" ->
        temp_result1 = {:some, false}
      "no" ->
        temp_result1 = {:some, false}
      "1" ->
        temp_result1 = {:some, true}
      "true" ->
        temp_result1 = {:some, true}
      "yes" ->
        temp_result1 = {:some, true}
      _ ->
        temp_result1 = :none
    end
    temp_result1 end)
    temp_result
  end

  @doc """
    Get integer configuration with validation.

    Demonstrates combining Option and Result for complex validation.

    @param key Configuration key
    @param min Minimum allowed value
    @param max Maximum allowed value
    @return Ok(value) if valid, Error(message) if invalid or missing
  """
  @spec get_int_with_range(String.t(), integer(), integer()) :: Result.t()
  def get_int_with_range(key, min, max) do
    ResultTools.flatMap(OptionTools.toResult(ConfigManager.getInt(key), "Configuration \"" <> key <> "\" is missing or not a valid number"), fn value -> temp_result = nil
    if (value < min), do: {:error, "Configuration \"" <> key <> "\" value " <> Integer.to_string(value) <> " is below minimum " <> Integer.to_string(min)}, else: nil
    if (value > max), do: {:error, "Configuration \"" <> key <> "\" value " <> Integer.to_string(value) <> " is above maximum " <> Integer.to_string(max)}, else: nil
    {:ok, value}
    temp_result end)
  end

  @doc """
    Validate database URL configuration.

    Shows complex validation using Option and Result together.

    @return Ok(url) if valid, Error(message) if invalid
  """
  @spec get_database_url() :: Result.t()
  def get_database_url() do
    ResultTools.flatMap(ConfigManager.getRequired("database_url"), fn url -> temp_result = nil
    if (case :binary.match(url, "://") do {pos, _} -> pos; :nomatch -> -1 end <= 0), do: {:error, "Database URL must contain protocol (e.g., postgres://)"}, else: nil
    if (String.length(url) < 10), do: {:error, "Database URL appears to be too short"}, else: nil
    {:ok, url}
    temp_result end)
  end

  @doc """
    Get application timeout with bounds checking.

    Demonstrates practical configuration validation.

    @return Timeout in seconds (between 1-300), or 30 as default
  """
  @spec get_timeout() :: integer()
  def get_timeout() do
    ResultTools.unwrapOr(ConfigManager.getIntWithRange("timeout", 1, 300), 30)
  end

  @doc """
    Check if debug mode is enabled.

    Shows boolean configuration with sensible default.

    @return True if debug mode is enabled
  """
  @spec is_debug_enabled() :: boolean()
  def is_debug_enabled() do
    OptionTools.unwrap(ConfigManager.getBool("debug"), false)
  end

  @doc """
    Get all configuration values that are set.

    Demonstrates filtering with Option integration.

    @return Map of all non-empty configuration values
  """
  @spec get_all_set_values() :: Map.t()
  def get_all_set_values() do
    result = Haxe.Ds.StringMap.new()
    this = ConfigManager.config
    temp_iterator = this.keys()
    (
      try do
        loop_fn = fn ->
          if (temp_iterator.hasNext()) do
            try do
              key = temp_iterator.next()
    _g = ConfigManager.get(key)
    case (case _g do {:some, _} -> 0; :none -> 1; _ -> -1 end) do
      0 ->
        _g = case _g do {:some, value} -> value; :none -> nil; _ -> nil end
    value = _g
    result.set(key, value)
      1 ->
        nil
    end
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
    result
  end

  @doc """
    Validate all required configuration values.

    Shows how to collect multiple validation results.

    @param requiredKeys Array of keys that must be present
    @return Ok(true) if all valid, Error(messages) listing all missing keys
  """
  @spec validate_required(Array.t()) :: Result.t()
  def validate_required(required_keys) do
    missing = []
    _g = 0
    Enum.map(required_keys, fn item -> item end)
    if (length(missing) > 0), do: {:error, "Missing required configuration: " <> Enum.join(missing, ", ")}, else: nil
    {:ok, true}
  end

end
