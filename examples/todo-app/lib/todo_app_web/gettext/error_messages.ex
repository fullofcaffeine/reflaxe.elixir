defmodule TodoAppWeb.Gettext.ErrorMessages do
  def required_field() do
    Gettext.dgettext("errors", "can't be blank")
  end
  def invalid_format() do
    Gettext.dgettext("errors", "has invalid format")
  end
  def too_short(min) do
    bindings = TranslationBindings_Impl_.set_int(TranslationBindings_Impl_.create(), "count", min)
    Gettext.dgettext("errors", "should be at least %{count} character(s)", bindings)
  end
  def too_long(max) do
    bindings = TranslationBindings_Impl_.set_int(TranslationBindings_Impl_.create(), "count", max)
    Gettext.dgettext("errors", "should be at most %{count} character(s)", bindings)
  end
  def not_found() do
    Gettext.dgettext("errors", "not found")
  end
  def unauthorized() do
    Gettext.dgettext("errors", "unauthorized")
  end
end