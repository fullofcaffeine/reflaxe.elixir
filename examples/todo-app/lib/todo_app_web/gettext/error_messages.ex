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
  @doc "Generated from Haxe required_field"
  def required_field() do
    :Gettext.dgettext("errors", "can't be blank")
  end

  @doc "Generated from Haxe invalid_format"
  def invalid_format() do
    :Gettext.dgettext("errors", "has invalid format")
  end

  @doc "Generated from Haxe too_short"
  def too_short(min) do
    bindings = :TranslationBindings_Impl_.setInt(:TranslationBindings_Impl_.create(), "count", min)
    :Gettext.dgettext("errors", "should be at least %{count} character(s)", bindings)
  end

  @doc "Generated from Haxe too_long"
  def too_long(max) do
    bindings = :TranslationBindings_Impl_.setInt(:TranslationBindings_Impl_.create(), "count", max)
    :Gettext.dgettext("errors", "should be at most %{count} character(s)", bindings)
  end

  @doc "Generated from Haxe not_found"
  def not_found() do
    :Gettext.dgettext("errors", "not found")
  end

  @doc "Generated from Haxe unauthorized"
  def unauthorized() do
    :Gettext.dgettext("errors", "unauthorized")
  end

end
