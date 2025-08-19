defmodule TodoAppWeb.Gettext.ErrorMessages do
  @moduledoc """
    TodoAppWeb.Gettext.ErrorMessages module generated from Haxe

     * Common error message translations for the application.
     *
     * This class provides pre-defined error messages using Gettext
     * for internationalization. All messages are in the "errors" domain
     * and can be translated to different languages.
  """

  # Static functions
  @doc """
    Returns the "required field" error message.
    @return Translated error message for required fields
  """
  @spec required_field() :: String.t()
  def required_field() do
    Gettext.dgettext("errors", "can't be blank")
  end

  @doc """
    Returns the "invalid format" error message.
    @return Translated error message for invalid format
  """
  @spec invalid_format() :: String.t()
  def invalid_format() do
    Gettext.dgettext("errors", "has invalid format")
  end

  @doc """
    Returns the "too short" error message with minimum length.
    @param min The minimum required length
    @return Translated error message with count interpolation
  """
  @spec too_short(integer()) :: String.t()
  def too_short(min) do
    bindings = TranslationBindings_Impl_.setInt(TranslationBindings_Impl_.create(), "count", min)
    Gettext.dgettext("errors", "should be at least %{count} character(s)", bindings)
  end

  @doc """
    Returns the "too long" error message with maximum length.
    @param max The maximum allowed length
    @return Translated error message with count interpolation
  """
  @spec too_long(integer()) :: String.t()
  def too_long(max) do
    bindings = TranslationBindings_Impl_.setInt(TranslationBindings_Impl_.create(), "count", max)
    Gettext.dgettext("errors", "should be at most %{count} character(s)", bindings)
  end

  @doc """
    Returns the "not found" error message.
    @return Translated error message for not found resources
  """
  @spec not_found() :: String.t()
  def not_found() do
    Gettext.dgettext("errors", "not found")
  end

  @doc """
    Returns the "unauthorized" error message.
    @return Translated error message for unauthorized access
  """
  @spec unauthorized() :: String.t()
  def unauthorized() do
    Gettext.dgettext("errors", "unauthorized")
  end

end
