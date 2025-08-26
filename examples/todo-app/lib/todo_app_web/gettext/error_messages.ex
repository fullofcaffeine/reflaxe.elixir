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
    TodoAppWeb.Gettext.dgettext("errors", "can't be blank")
  end

  @doc "Generated from Haxe invalid_format"
  def invalid_format() do
    TodoAppWeb.Gettext.dgettext("errors", "has invalid format")
  end

  @doc "Generated from Haxe too_short"
  def too_short(min) do
    _bindings = TranslationBindings_Impl_.set_int(TranslationBindings_Impl_.create(), "count", min)

    TodoAppWeb.Gettext.dgettext("errors", "should be at least %{count} character(s)", bindings)
  end

  @doc "Generated from Haxe too_long"
  def too_long(max) do
    _bindings = TranslationBindings_Impl_.set_int(TranslationBindings_Impl_.create(), "count", max)

    TodoAppWeb.Gettext.dgettext("errors", "should be at most %{count} character(s)", bindings)
  end

  @doc "Generated from Haxe not_found"
  def not_found() do
    TodoAppWeb.Gettext.dgettext("errors", "not found")
  end

  @doc "Generated from Haxe unauthorized"
  def unauthorized() do
    TodoAppWeb.Gettext.dgettext("errors", "unauthorized")
  end

end
