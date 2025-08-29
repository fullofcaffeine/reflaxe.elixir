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
    bindings = :TranslationBindings_Impl_.set(:TranslationBindings_Impl_.create(), "name", name)
    :Gettext.gettext("Welcome %{name}!", bindings)
  end

  @doc "Generated from Haxe success"
  def success() do
    :Gettext.gettext("Operation completed successfully")
  end

  @doc "Generated from Haxe loading"
  def loading() do
    :Gettext.gettext("Loading...")
  end

  @doc "Generated from Haxe save"
  def save() do
    :Gettext.gettext("Save")
  end

  @doc "Generated from Haxe cancel"
  def cancel() do
    :Gettext.gettext("Cancel")
  end

  @doc "Generated from Haxe delete"
  def delete() do
    :Gettext.gettext("Delete")
  end

  @doc "Generated from Haxe edit"
  def edit() do
    :Gettext.gettext("Edit")
  end

  @doc "Generated from Haxe confirm_delete"
  def confirm_delete() do
    :Gettext.gettext("Are you sure you want to delete this item?")
  end

end
