defmodule TodoAppWeb.Gettext.ErrorMessages do
  def required_field() do
    fn -> Gettext.dgettext("errors", "can't be blank") end
  end
  def invalid_format() do
    fn -> Gettext.dgettext("errors", "has invalid format") end
  end
  def too_short() do
    fn min -> bindings = TranslationBindings_Impl_.set_int(TranslationBindings_Impl_.create(), "count", min)
Gettext.dgettext("errors", "should be at least %{count} character(s)", bindings) end
  end
  def too_long() do
    fn max -> bindings = TranslationBindings_Impl_.set_int(TranslationBindings_Impl_.create(), "count", max)
Gettext.dgettext("errors", "should be at most %{count} character(s)", bindings) end
  end
  def not_found() do
    fn -> Gettext.dgettext("errors", "not found") end
  end
  def unauthorized() do
    fn -> Gettext.dgettext("errors", "unauthorized") end
  end
end