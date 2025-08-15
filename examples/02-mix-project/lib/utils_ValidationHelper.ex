defmodule ValidationHelper do
  use Bitwise
  @moduledoc """
  ValidationHelper module generated from Haxe
  
  
 * ValidationHelper - Input validation utilities for Mix project
 * 
 * This module provides comprehensive validation functions that can be
 * used throughout a Mix project for data integrity and security.
 
  """

  # Module functions - generated with @:module syntax sugar

  @doc "
     * Validates user input data comprehensively
     * Returns validation result with detailed error information
     "
  @spec validate_user_input(term()) :: term()
  def validate_user_input(data) do
    errors = []
    if (arg0.name == nil || length(arg0.name.trim()) == 0), do: errors ++ ["Name is required"], else: if (length(arg0.name.trim()) < 2), do: errors ++ ["Name must be at least 2 characters"], else: if (length(arg0.name.trim()) > 50), do: errors ++ ["Name must not exceed 50 characters"], else: nil
    email_result = ValidationHelper.validateEmail(arg0.email)
    if (!email_result.valid), do: errors ++ ["Email: " <> email_result.error], else: nil
    if (arg0.age != nil) do
      age_result = ValidationHelper.validateAge(arg0.age)
      if (!age_result.valid), do: errors ++ ["Age: " <> age_result.error], else: nil
    end
    temp_maybe_var = nil
    if (length(errors) == 0), do: temp_maybe_var = ValidationHelper.sanitizeUserData(arg0), else: temp_maybe_var = nil
    %{valid: length(errors) == 0, errors: errors, data: temp_maybe_var}
  end

  @doc "
     * Validates email address format and domain
     "
  @spec validate_email(term()) :: term()
  def validate_email(email) do
    if (arg0 == nil), do: %{valid: false, error: "Email is required"}, else: nil
    email_str = StringTools.trim(Std.string(arg0))
    if (String.length(email_str) == 0), do: %{valid: false, error: "Email cannot be empty"}, else: nil
    if (String.length(email_str) > 254), do: %{valid: false, error: "Email is too long"}, else: nil
    if (!ValidationHelper.isValidEmailFormat(email_str)), do: %{valid: false, error: "Invalid email format"}, else: nil
    domain = ValidationHelper.extractDomain(email_str)
    if (!ValidationHelper.isValidDomain(domain)), do: %{valid: false, error: "Invalid email domain"}, else: nil
    %{valid: true, email: String.downcase(email_str), domain: domain}
  end

  @doc "
     * Validates age input
     "
  @spec validate_age(term()) :: term()
  def validate_age(age) do
    if (arg0 == nil), do: %{valid: false, error: "Age is required"}, else: nil
    age_num = nil
    try do
      age_num = Std.parseInt(Std.string(arg0))
    if (age_num == nil), do: throw("Invalid number"), else: nil
    rescue
      e ->
        %{valid: false, error: "Age must be a valid number"}
    end
    if (age_num < 0), do: %{valid: false, error: "Age cannot be negative"}, else: nil
    if (age_num > 150), do: %{valid: false, error: "Age seems unrealistic"}, else: nil
    %{valid: true, age: age_num, category: ValidationHelper.categorizeAge(age_num)}
  end

  @doc "
     * Validates password strength
     "
  @spec validate_password(String.t()) :: term()
  def validate_password(password) do
    if (arg0 == nil), do: %{valid: false, error: "Password is required", strength: 0}, else: nil
    if (String.length(arg0) < 8), do: %{valid: false, error: "Password must be at least 8 characters", strength: 1}, else: nil
    strength = ValidationHelper.calculatePasswordStrength(arg0)
    errors = []
    if (strength.score < 3) do
      if (!strength.has_lowercase), do: errors ++ ["Must contain lowercase letters"], else: nil
      if (!strength.has_uppercase), do: errors ++ ["Must contain uppercase letters"], else: nil
      if (!strength.has_numbers), do: errors ++ ["Must contain numbers"], else: nil
      if (!strength.has_special_chars), do: errors ++ ["Must contain special characters"], else: nil
    end
    temp_maybe_string = nil
    if (length(errors) > 0), do: temp_maybe_string = Enum.join(errors, ", "), else: temp_maybe_string = nil
    %{valid: strength.score >= 3, error: temp_maybe_string, strength: strength.score, details: strength}
  end

  @doc "
     * Validates and sanitizes text input
     "
  @spec validate_and_sanitize_text(String.t(), integer(), integer()) :: term()
  def validate_and_sanitize_text(text, min_length, max_length) do
    if (arg0 == nil) do
      temp_maybe_string = nil
      if (arg1 > 0), do: temp_maybe_string = "Text is required", else: temp_maybe_string = nil
      %{valid: arg1 == 0, error: temp_maybe_string, sanitized: ""}
    end
    sanitized = ValidationHelper.sanitizeText(arg0)
    if (String.length(sanitized) < arg1), do: %{valid: false, error: "Text must be at least " <> Integer.to_string(arg1) <> " characters", sanitized: sanitized}, else: nil
    if (String.length(sanitized) > arg2), do: %{valid: false, error: "Text must not exceed " <> Integer.to_string(arg2) <> " characters", sanitized: sanitized}, else: nil
    %{valid: true, error: nil, sanitized: sanitized}
  end

  @doc "
     * Validates URL format
     "
  @spec validate_url(String.t()) :: term()
  def validate_url(url) do
    if (arg0 == nil || String.length(StringTools.trim(arg0)) == 0), do: %{valid: false, error: "URL is required"}, else: nil
    trimmed = StringTools.trim(arg0)
    if (!ValidationHelper.isValidUrlFormat(trimmed)), do: %{valid: false, error: "Invalid URL format"}, else: nil
    %{valid: true, url: trimmed, protocol: ValidationHelper.extractProtocol(trimmed), domain: ValidationHelper.extractUrlDomain(trimmed)}
  end

  @doc "Function is_valid_email_format"
  defp is_valid_email_format(email) do
    pattern = EReg.new("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", "")
    pattern.match(arg0)
  end

  @doc "Function extract_domain"
  defp extract_domain(email) do
    at_index = case :binary.match(arg0, "@") do {pos, _} -> pos; :nomatch -> -1 end
    temp_result = nil
    if (at_index > 0), do: temp_result = String.slice(arg0, at_index + 1..-1), else: temp_result = ""
    temp_result
  end

  @doc "Function is_valid_domain"
  defp is_valid_domain(domain) do
    if (String.length(arg0) < 4), do: false, else: nil
    if (case :binary.match(arg0, ".") do {pos, _} -> pos; :nomatch -> -1 end == -1), do: false, else: nil
    true
  end

  @doc "Function categorize_age"
  defp categorize_age(age) do
    if (arg0 < 13), do: "child", else: nil
    if (arg0 < 20), do: "teenager", else: nil
    if (arg0 < 65), do: "adult", else: nil
    "senior"
  end

  @doc "Function calculate_password_strength"
  defp calculate_password_strength(password) do
    has_lowercase = EReg.new("[a-z]", "").match(arg0)
    has_uppercase = EReg.new("[A-Z]", "").match(arg0)
    has_numbers = EReg.new("[0-9]", "").match(arg0)
    has_special_chars = EReg.new("[^a-zA-Z0-9]", "").match(arg0)
    score = 0
    if (String.length(arg0) >= 8), do: score = score + 1, else: nil
    if (has_lowercase), do: score = score + 1, else: nil
    if (has_uppercase), do: score = score + 1, else: nil
    if (has_numbers), do: score = score + 1, else: nil
    if (has_special_chars), do: score = score + 1, else: nil
    %{score: score, hasLowercase: has_lowercase, hasUppercase: has_uppercase, hasNumbers: has_numbers, hasSpecialChars: has_special_chars, length: String.length(arg0)}
  end

  @doc "Function sanitize_text"
  defp sanitize_text(text) do
    sanitized = StringTools.trim(arg0)
    sanitized = StringTools.replace(sanitized, "<", "&lt;")
    sanitized = StringTools.replace(sanitized, ">", "&gt;")
    sanitized = StringTools.replace(sanitized, "\"", "&quot;")
    sanitized = StringTools.replace(sanitized, "'", "&#39;")
    sanitized
  end

  @doc "Function sanitize_user_data"
  defp sanitize_user_data(data) do
    temp_maybe_string = nil
    if (arg0.name != nil), do: temp_maybe_string = ValidationHelper.sanitizeText(Std.string(arg0.name)), else: temp_maybe_string = nil
    temp_maybe_string1 = nil
    if (arg0.email != nil), do: temp_maybe_string1 = String.downcase(StringTools.trim(Std.string(arg0.email))), else: temp_maybe_string1 = nil
    %{name: temp_maybe_string, email: temp_maybe_string1, age: arg0.age}
  end

  @doc "Function is_valid_url_format"
  defp is_valid_url_format(url) do
    pattern = EReg.new("^https?://[^\\s/$.?#].[^\\s]*$", "i")
    pattern.match(arg0)
  end

  @doc "Function extract_protocol"
  defp extract_protocol(url) do
    colon_index = case :binary.match(arg0, "://") do {pos, _} -> pos; :nomatch -> -1 end
    temp_result = nil
    if (colon_index > 0), do: temp_result = String.slice(arg0, 0, colon_index), else: temp_result = ""
    temp_result
  end

  @doc "Function extract_url_domain"
  defp extract_url_domain(url) do
    protocol_end = case :binary.match(arg0, "://") do {pos, _} -> pos; :nomatch -> -1 end + 3
    path_start = case :binary.match(arg0, "/") do {pos, _} -> pos; :nomatch -> -1 end
    temp_string = nil
    if (path_start > 0), do: temp_string = String.slice(arg0, protocol_end, path_start - protocol_end), else: temp_string = String.slice(arg0, protocol_end..-1)
    temp_string
  end

  @doc "
     * Main function for compilation testing
     "
  @spec main() :: nil
  def main() do
    Log.trace("ValidationHelper compiled successfully for Mix project!", %{fileName: "src_haxe/utils/ValidationHelper.hx", lineNumber: 306, className: "utils.ValidationHelper", methodName: "main"})
  end

end
