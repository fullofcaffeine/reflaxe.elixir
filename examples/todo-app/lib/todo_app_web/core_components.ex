defmodule TodoAppWeb.CoreComponents do
  @moduledoc """
    TodoAppWeb.CoreComponents module generated from Haxe

     * Core UI components for Phoenix applications.
     *
     * This module provides reusable UI components like modals, flash messages,
     * tables, and forms that are commonly used across Phoenix LiveView applications.
     * These components follow Phoenix's component patterns and conventions.
     *
     * All components return type-safe HtmlComponent instead of Dynamic,
     * providing compile-time safety and IntelliSense support.
  """

  # Static functions
  @doc """
    Renders a modal dialog component.

    @param id The unique identifier for the modal
    @param show Whether the modal should be visible
    @return Type-safe HTML component for the modal
  """
  @spec modal(String.t(), boolean()) :: HtmlComponent.t()
  def modal(id, show) do
    HtmlComponent_Impl_.empty()
  end

  @doc """
    Renders flash messages for user notifications.

    @param type The type of flash message (info, success, warning, error)
    @param message The message content to display
    @return Type-safe HTML component for the flash message
  """
  @spec flash(String.t(), String.t()) :: HtmlComponent.t()
  def flash(type, message) do
    HtmlComponent_Impl_.empty()
  end

  @doc """
    Renders a simple form component.

    @param for_schema The schema or changeset for the form
    @param action The form submission action/URL
    @return Type-safe HTML component for the form
  """
  @spec simple_form(String.t(), String.t()) :: HtmlComponent.t()
  def simple_form(for_schema, action) do
    HtmlComponent_Impl_.empty()
  end

  @doc """
    Renders a button component.

    @param label The button text
    @param type The button type (button, submit, reset)
    @param disabled Whether the button is disabled
    @return Type-safe HTML component for the button
  """
  @spec button(String.t(), String.t(), boolean()) :: HtmlComponent.t()
  def button(label, type, disabled) do
    HtmlComponent_Impl_.empty()
  end

  @doc """
    Renders an input field component.

    @param field The form field name
    @param label The input label
    @param type The input type (text, email, password, etc.)
    @param required Whether the field is required
    @return Type-safe HTML component for the input
  """
  @spec input(String.t(), String.t(), String.t(), boolean()) :: HtmlComponent.t()
  def input(field, label, type, required) do
    HtmlComponent_Impl_.empty()
  end

  @doc """
    Renders a data table component.

    @param id The table identifier
    @param rows The data rows to display (as array of structs)
    @return Type-safe HTML component for the table
  """
  @spec table(String.t(), Array.t()) :: HtmlComponent.t()
  def table(id, rows) do
    HtmlComponent_Impl_.empty()
  end

  @doc """
    Renders a list component.

    @param items The items to display in the list
    @return Type-safe HTML component for the list
  """
  @spec list(Array.t()) :: HtmlComponent.t()
  def list(items) do
    HtmlComponent_Impl_.empty()
  end

  @doc """
    Renders a back navigation link.

    @param navigate The navigation target path
    @return Type-safe HTML component for the back link
  """
  @spec back(String.t()) :: HtmlComponent.t()
  def back(navigate) do
    HtmlComponent_Impl_.empty()
  end

  @doc """
    Renders an icon component.

    @param name The icon name
    @param className Optional CSS classes
    @return Type-safe HTML component for the icon
  """
  @spec icon(String.t(), Null.t()) :: HtmlComponent.t()
  def icon(name, class_name) do
    HtmlComponent_Impl_.empty()
  end

  @doc """
    Renders a header component.

    @param title The header title
    @param subtitle Optional subtitle
    @return Type-safe HTML component for the header
  """
  @spec header(String.t(), Null.t()) :: HtmlComponent.t()
  def header(title, subtitle) do
    HtmlComponent_Impl_.empty()
  end

  @doc """
    Translates an error message from an Ecto changeset error.
    Used for form validation error messages.

    @param error The error tuple from Ecto
    @return The translated error message string
  """
  @spec translate_error(term()) :: String.t()
  def translate_error(error) do
    error.msg
  end

  @doc """
    Returns a list of all error messages for a field.

    @param field The field to get errors for
    @return Array of error messages
  """
  @spec errors_for_field(String.t()) :: Array.t()
  def errors_for_field(field) do
    []
  end

end
