defmodule TodoAppWeb.Gettext.UIMessages do
  def welcome(name) do
    bindings = TranslationBindings_Impl_.set(TranslationBindings_Impl_.create(), "name", name)
    TodoAppWeb.Gettext.gettext("Welcome %{name}!", bindings)
  end
  def success() do
    TodoAppWeb.Gettext.gettext("Operation completed successfully")
  end
  def loading() do
    TodoAppWeb.Gettext.gettext("Loading...")
  end
  def save() do
    TodoAppWeb.Gettext.gettext("Save")
  end
  def cancel() do
    TodoAppWeb.Gettext.gettext("Cancel")
  end
  def delete() do
    TodoAppWeb.Gettext.gettext("Delete")
  end
  def edit() do
    TodoAppWeb.Gettext.gettext("Edit")
  end
  def confirm_delete() do
    TodoAppWeb.Gettext.gettext("Are you sure you want to delete this item?")
  end
end