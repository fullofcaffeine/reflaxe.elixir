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
    case (type.elem(0)) do
      0 ->
        temp_result = "info"
      1 ->
        temp_result = "success"
      2 ->
        temp_result = "warning"
      3 ->
        temp_result = "error"
    end
    temp_result
  end

  @doc "Generated from Haxe fromString"
  def from_string(str) do
    temp_result = nil

    temp_result = nil
    _g = str.toLowerCase()
    case (_g) do
      "error" ->
        temp_result = :Error
      "info" ->
        temp_result = :Info
      "success" ->
        temp_result = :Success
      "warning" ->
        temp_result = :Warning
      _ ->
        temp_result = :Info
    end
    temp_result
  end

  @doc "Generated from Haxe getCssClass"
  def get_css_class(type) do
    temp_result = nil

    temp_result = nil
    case (type.elem(0)) do
      0 ->
        temp_result = "bg-blue-50 border-blue-200 text-blue-800"
      1 ->
        temp_result = "bg-green-50 border-green-200 text-green-800"
      2 ->
        temp_result = "bg-yellow-50 border-yellow-200 text-yellow-800"
      3 ->
        temp_result = "bg-red-50 border-red-200 text-red-800"
    end
    temp_result
  end

  @doc "Generated from Haxe getIconName"
  def get_icon_name(type) do
    temp_result = nil

    temp_result = nil
    case (type.elem(0)) do
      0 ->
        temp_result = "information-circle"
      1 ->
        temp_result = "check-circle"
      2 ->
        temp_result = "exclamation-triangle"
      3 ->
        temp_result = "x-circle"
    end
    temp_result
  end

end
