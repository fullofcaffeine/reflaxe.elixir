defmodule FlashTypeTools do
  @moduledoc """
    FlashTypeTools module generated from Haxe

     * Helper functions for FlashType enum
  """

  # Static functions
  @doc "Generated from Haxe toString"
  def format(type) do
    temp_result = nil

    temp_result = nil

    case _type do
      :info -> "info"
      :success -> "success"
      :warning -> "warning"
      :error -> "error"
    end

    temp_result
  end

  @doc "Generated from Haxe fromString"
  def from_string(str) do
    temp_result = nil

    g_array = str.to_lower_case()
    case g_array do
      "error" -> :error
      "info" -> :info
      "success" -> :success
      "warning" -> :warning
      _ -> :info
    end

    temp_result
  end

  @doc "Generated from Haxe getCssClass"
  def get_css_class(type) do
    temp_result = nil

    case _type do
      :info -> "bg-blue-50 border-blue-200 text-blue-800"
      :success -> "bg-green-50 border-green-200 text-green-800"
      :warning -> "bg-yellow-50 border-yellow-200 text-yellow-800"
      :error -> "bg-red-50 border-red-200 text-red-800"
    end

    temp_result
  end

  @doc "Generated from Haxe getIconName"
  def get_icon_name(type) do
    temp_result = nil

    case _type do
      :info -> "information-circle"
      :success -> "check-circle"
      :warning -> "exclamation-triangle"
      :error -> "x-circle"
    end

    temp_result
  end

end
