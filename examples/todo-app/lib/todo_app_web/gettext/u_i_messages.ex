defmodule TodoAppWeb.Gettext.UIMessages do
  @moduledoc """
    TodoAppWeb.Gettext.UIMessages module generated from Haxe

     * Common UI message translations for the application.
     *
     * This class provides pre-defined UI messages using Gettext
     * for internationalization. These messages are commonly used
     * throughout the application's user interface.
  """

  # Static functions
  @doc "Generated from Haxe welcome"
  def welcome(name) do
    _bindings = TranslationBindings_Impl_.set(TranslationBindings_Impl_.create(), "name", name)

    TodoAppWeb.Gettext.gettext("Welcome %{name}!", _bindings)
  end

  @doc "Generated from Haxe success"
  def success() do
    TodoAppWeb.Gettext.gettext("Operation completed successfully")
  end

  @doc "Generated from Haxe loading"
  def loading() do
    TodoAppWeb.Gettext.gettext("Loading...")
  end

  @doc "Generated from Haxe save"
  def save() do
    TodoAppWeb.Gettext.gettext("Save")
  end

  @doc "Generated from Haxe cancel"
  def cancel() do
    TodoAppWeb.Gettext.gettext("Cancel")
  end

  @doc "Generated from Haxe delete"
  def delete() do
    TodoAppWeb.Gettext.gettext("Delete")
  end

  @doc "Generated from Haxe edit"
  def edit() do
    TodoAppWeb.Gettext.gettext("Edit")
  end

  @doc "Generated from Haxe confirm_delete"
  def confirm_delete() do
    TodoAppWeb.Gettext.gettext("Are you sure you want to delete this item?")
  end

end
