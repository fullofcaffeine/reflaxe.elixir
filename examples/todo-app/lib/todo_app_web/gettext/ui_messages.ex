defmodule TodoAppWeb.Gettext.UIMessages do
  def welcome() do
    fn name -> bindings = TranslationBindings_Impl_.set(TranslationBindings_Impl_.create(), "name", name)
Gettext.gettext("Welcome %{name}!", bindings) end
  end
  def success() do
    fn -> Gettext.gettext("Operation completed successfully") end
  end
  def loading() do
    fn -> Gettext.gettext("Loading...") end
  end
  def save() do
    fn -> Gettext.gettext("Save") end
  end
  def cancel() do
    fn -> Gettext.gettext("Cancel") end
  end
  def delete() do
    fn -> Gettext.gettext("Delete") end
  end
  def edit() do
    fn -> Gettext.gettext("Edit") end
  end
  def confirm_delete() do
    fn -> Gettext.gettext("Are you sure you want to delete this item?") end
  end
end