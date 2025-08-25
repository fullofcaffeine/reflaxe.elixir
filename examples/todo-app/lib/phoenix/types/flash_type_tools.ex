defmodule FlashTypeTools do
  @moduledoc """
    FlashTypeTools module generated from Haxe

     * Helper functions for FlashType enum
  """

  # Static functions
  @doc """
    Convert FlashType to string for Phoenix compatibility

    @param type Flash type enum value
    @return String Phoenix-compatible string representation
  """
  @spec format(FlashType.t()) :: String.t()
  def format(type) do
    case (case type do :info -> 0; :success -> 1; :warning -> 2; :error -> 3; _ -> -1 end) do
      0 -> "info"
      1 -> "success"
      2 -> "warning"
      3 -> "error"
    end
  end

  @doc """
    Parse string to FlashType

    @param str String representation of flash type
    @return FlashType Enum value, defaults to Info for unknown strings
  """
  @spec from_string(String.t()) :: FlashType.t()
  def from_string(str) do
    (
          temp_result = nil
          (
          g_array = str.to_lower_case()
          case g_array do
      "error" -> :error
      "info" -> :info
      "success" -> :success
      "warning" -> :warning
      _ -> :info
    end
        )
          temp_result
        )
  end

  @doc """
    Get CSS class for flash type
    Standard Tailwind CSS classes for flash styling

    @param type Flash type enum value
    @return String CSS class string
  """
  @spec get_css_class(FlashType.t()) :: String.t()
  def get_css_class(type) do
    case (case type do :info -> 0; :success -> 1; :warning -> 2; :error -> 3; _ -> -1 end) do
      0 -> "bg-blue-50 border-blue-200 text-blue-800"
      1 -> "bg-green-50 border-green-200 text-green-800"
      2 -> "bg-yellow-50 border-yellow-200 text-yellow-800"
      3 -> "bg-red-50 border-red-200 text-red-800"
    end
  end

  @doc """
    Get icon name for flash type
    Standard icon names for flash message display

    @param type Flash type enum value
    @return String Icon name (compatible with Heroicons or similar)
  """
  @spec get_icon_name(FlashType.t()) :: String.t()
  def get_icon_name(type) do
    case (case type do :info -> 0; :success -> 1; :warning -> 2; :error -> 3; _ -> -1 end) do
      0 -> "information-circle"
      1 -> "check-circle"
      2 -> "exclamation-triangle"
      3 -> "x-circle"
    end
  end

end
