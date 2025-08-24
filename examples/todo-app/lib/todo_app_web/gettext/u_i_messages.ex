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
  @doc """
    Returns a welcome message with the user's name.
    @param name The name to include in the welcome message
    @return Translated welcome message with name interpolation
  """
  @spec welcome(String.t()) :: String.t()
  def welcome(name) do
    (
          bindings = TranslationBindings_Impl_.set(TranslationBindings_Impl_.create(), "name", name)
          TodoAppWeb.Gettext.gettext("Welcome %{name}!", bindings)
        )
  end

  @doc """
    Returns a generic success message.
    @return Translated success message
  """
  @spec success() :: String.t()
  def success() do
    TodoAppWeb.Gettext.gettext("Operation completed successfully")
  end

  @doc """
    Returns a loading message.
    @return Translated loading message
  """
  @spec loading() :: String.t()
  def loading() do
    TodoAppWeb.Gettext.gettext("Loading...")
  end

  @doc """
    Returns the "Save" button label.
    @return Translated save label
  """
  @spec save() :: String.t()
  def save() do
    TodoAppWeb.Gettext.gettext("Save")
  end

  @doc """
    Returns the "Cancel" button label.
    @return Translated cancel label
  """
  @spec cancel() :: String.t()
  def cancel() do
    TodoAppWeb.Gettext.gettext("Cancel")
  end

  @doc """
    Returns the "Delete" button label.
    @return Translated delete label
  """
  @spec delete() :: String.t()
  def delete() do
    TodoAppWeb.Gettext.gettext("Delete")
  end

  @doc """
    Returns the "Edit" button label.
    @return Translated edit label
  """
  @spec edit() :: String.t()
  def edit() do
    TodoAppWeb.Gettext.gettext("Edit")
  end

  @doc """
    Returns a confirmation message for delete actions.
    @return Translated delete confirmation message
  """
  @spec confirm_delete() :: String.t()
  def confirm_delete() do
    TodoAppWeb.Gettext.gettext("Are you sure you want to delete this item?")
  end

end
