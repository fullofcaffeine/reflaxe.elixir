defmodule TodoAppWeb.Gettext.UIMessages do
  def welcome(name) do
    bindings = TranslationBindings_Impl_.set(TranslationBindings_Impl_.create(), "name", name)
    Gettext.gettext("Welcome %{name}!", bindings)
  end
  def success() do
    Gettext.gettext("Operation completed successfully")
  end
  def loading() do
    Gettext.gettext("Loading...")
  end
  def save() do
    Gettext.gettext("Save")
  end
  def cancel() do
    Gettext.gettext("Cancel")
  end
  def delete() do
    Gettext.gettext("Delete")
  end
  def edit() do
    Gettext.gettext("Edit")
  end
  def confirm_delete() do
    Gettext.gettext("Are you sure you want to delete this item?")
  end
end