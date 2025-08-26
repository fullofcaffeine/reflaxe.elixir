defmodule FlashTypeTools do
  @moduledoc """
    FlashTypeTools module generated from Haxe

     * Helper functions for FlashType enum
  """

  # Static functions
  @doc "Generated from Haxe toString"
  def format(_type) do
    temp_result = nil

    case (case type do :info -> 0; :success -> 1; :warning -> 2; :error -> 3; _ -> -1 end) do
      0 -> "info"
      1 -> "success"
      2 -> "warning"
      3 -> "error"
    end

    temp_result
  end

  @doc "Generated from Haxe fromString"
  def from_string(str) do
    temp_result = nil

    g_array = str.to_lower_case()
    case (g_array) do
      _ -> :info
    end

    temp_result
  end

  @doc "Generated from Haxe getCssClass"
  def get_css_class(_type) do
    temp_result = nil

    case (case type do :info -> 0; :success -> 1; :warning -> 2; :error -> 3; _ -> -1 end) do
      0 -> "bg-blue-50 border-blue-200 text-blue-800"
      1 -> "bg-green-50 border-green-200 text-green-800"
      2 -> "bg-yellow-50 border-yellow-200 text-yellow-800"
      3 -> "bg-red-50 border-red-200 text-red-800"
    end

    temp_result
  end

  @doc "Generated from Haxe getIconName"
  def get_icon_name(_type) do
    temp_result = nil

    case (case type do :info -> 0; :success -> 1; :warning -> 2; :error -> 3; _ -> -1 end) do
      0 -> "information-circle"
      1 -> "check-circle"
      2 -> "exclamation-triangle"
      3 -> "x-circle"
    end

    temp_result
  end

end
