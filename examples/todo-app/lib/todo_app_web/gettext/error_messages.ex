defmodule TodoAppWeb.Gettext.ErrorMessages do
  def required_field() do
    TodoAppWeb.Gettext.dgettext("errors", "can't be blank")
  end
  def invalid_format() do
    TodoAppWeb.Gettext.dgettext("errors", "has invalid format")
  end
  def too_short(_min) do
    TodoAppWeb.Gettext.dgettext("errors", "should be at least %{count} character(s)", bindings)
  end
  def too_long(_max) do
    TodoAppWeb.Gettext.dgettext("errors", "should be at most %{count} character(s)", bindings)
  end
  def not_found() do
    TodoAppWeb.Gettext.dgettext("errors", "not found")
  end
  def unauthorized() do
    TodoAppWeb.Gettext.dgettext("errors", "unauthorized")
  end
end