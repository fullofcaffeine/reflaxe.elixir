defmodule Flash do
  @moduledoc """
    Flash module generated from Haxe

     * Type-safe flash message builder and utilities
  """

  # Static functions
  @doc """
    Create an info flash message

    @param message Primary message text
    @param title Optional title
    @return FlashMessage Structured flash message
  """
  @spec info(String.t(), Null.t()) :: FlashMessage.t()
  def info(message, title) do
    %{"type" => :info, "message" => message, "title" => title, "dismissible" => true}
  end

  @doc """
    Create a success flash message

    @param message Primary message text
    @param title Optional title
    @return FlashMessage Structured flash message
  """
  @spec success(String.t(), Null.t()) :: FlashMessage.t()
  def success(message, title) do
    %{"type" => :success, "message" => message, "title" => title, "dismissible" => true, "timeout" => 5000}
  end

  @doc """
    Create a warning flash message

    @param message Primary message text
    @param title Optional title
    @return FlashMessage Structured flash message
  """
  @spec warning(String.t(), Null.t()) :: FlashMessage.t()
  def warning(message, title) do
    %{"type" => :warning, "message" => message, "title" => title, "dismissible" => true}
  end

  @doc """
    Create an error flash message

    @param message Primary message text
    @param details Optional array of error details
    @param title Optional title
    @return FlashMessage Structured flash message
  """
  @spec error(String.t(), Null.t(), Null.t()) :: FlashMessage.t()
  def error(message, details, title) do
    %{"type" => :error, "message" => message, "details" => details, "title" => title, "dismissible" => true}
  end

  @doc """
    Create a validation error flash from changeset errors

    @param message Primary message text
    @param changeset Ecto changeset with validation errors
    @return FlashMessage Error flash with validation details
  """
  @spec validation_error(String.t(), term()) :: FlashMessage.t()
  def validation_error(message, changeset) do
    (
          errors = Flash.extract_changeset_errors(changeset)
          %{"type" => :error, "message" => message, "details" => errors, "title" => "Validation Failed", "dismissible" => true}
        )
  end

  @doc """
    Convert FlashMessage to Phoenix-compatible map
    Used when passing flash messages to Phoenix functions

    @param flash Structured flash message
    @return Dynamic Phoenix-compatible flash map
  """
  @spec to_phoenix_flash(FlashMessage.t()) :: term()
  def to_phoenix_flash(flash) do
    result = %{"type" => FlashTypeTools.to_string(flash.type), "message" => flash.message}
    if ((flash.title != nil)) do
          Reflect.set_field(result, "title", flash.title)
        end
    if ((flash.details != nil)) do
          Reflect.set_field(result, "details", flash.details)
        end
    if ((flash.dismissible != nil)) do
          Reflect.set_field(result, "dismissible", flash.dismissible)
        end
    if ((flash.timeout != nil)) do
          Reflect.set_field(result, "timeout", flash.timeout)
        end
    if ((flash.action != nil)) do
          Reflect.set_field(result, "action", flash.action)
        end
    result
  end

  @doc """
    Parse Phoenix flash map to structured FlashMessage
    Used when receiving flash data from Phoenix

    @param phoenixFlash Phoenix flash map
    @return FlashMessage Structured flash message
  """
  @spec from_phoenix_flash(term()) :: FlashMessage.t()
  def from_phoenix_flash(phoenix_flash) do
    (
          type = FlashTypeTools.from_string(Reflect.field(phoenix_flash, "type"))
          message = Reflect.field(phoenix_flash, "message")
          %{"type" => type, "message" => message, "title" => Reflect.field(phoenix_flash, "title"), "details" => Reflect.field(phoenix_flash, "details"), "dismissible" => Reflect.field(phoenix_flash, "dismissible"), "timeout" => Reflect.field(phoenix_flash, "timeout"), "action" => Reflect.field(phoenix_flash, "action")}
        )
  end

  @doc """
    Extract error messages from Ecto changeset
    Helper function for validation error handling

    @param changeset Ecto changeset with errors
    @return Array<String> List of error messages
  """
  @spec extract_changeset_errors(term()) :: Array.t()
  def extract_changeset_errors(changeset) do
    (
          errors = []
          changeset_errors = Reflect.field(changeset, "errors")
          if ((changeset_errors != nil)) do
          (
          g_counter = 0
          g_array = Reflect.fields(changeset_errors)
          Enum.each(, fn field -> 
      field_errors = Reflect.field(changeset_errors, field)
      if Std.is_of_type(field_errors, Array) do
          (
          g_counter = 0
          g_array = field_errors
          Enum.each(, fn error -> 
      errors ++ ["" <> field <> ": " <> Std.string(error)]
    end)
        )
        else
          errors ++ ["" <> field <> ": " <> field_errors]
        end
    end)
        )
        end
          errors
        )
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
