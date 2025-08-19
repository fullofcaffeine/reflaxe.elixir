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
    %{"type" => FlashType.info, "message" => message, "title" => title, "dismissible" => true}
  end

  @doc """
    Create a success flash message

    @param message Primary message text
    @param title Optional title
    @return FlashMessage Structured flash message
  """
  @spec success(String.t(), Null.t()) :: FlashMessage.t()
  def success(message, title) do
    %{"type" => FlashType.success, "message" => message, "title" => title, "dismissible" => true, "timeout" => 5000}
  end

  @doc """
    Create a warning flash message

    @param message Primary message text
    @param title Optional title
    @return FlashMessage Structured flash message
  """
  @spec warning(String.t(), Null.t()) :: FlashMessage.t()
  def warning(message, title) do
    %{"type" => FlashType.warning, "message" => message, "title" => title, "dismissible" => true}
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
    %{"type" => FlashType.error, "message" => message, "details" => details, "title" => title, "dismissible" => true}
  end

  @doc """
    Create a validation error flash from changeset errors

    @param message Primary message text
    @param changeset Ecto changeset with validation errors
    @return FlashMessage Error flash with validation details
  """
  @spec validation_error(String.t(), term()) :: FlashMessage.t()
  def validation_error(message, changeset) do
    errors = Flash.extractChangesetErrors(changeset)
    %{"type" => FlashType.error, "message" => message, "details" => errors, "title" => "Validation Failed", "dismissible" => true}
  end

  @doc """
    Convert FlashMessage to Phoenix-compatible map
    Used when passing flash messages to Phoenix functions

    @param flash Structured flash message
    @return Dynamic Phoenix-compatible flash map
  """
  @spec to_phoenix_flash(FlashMessage.t()) :: term()
  def to_phoenix_flash(flash) do
    result = %{"type" => FlashTypeTools.toString(flash.type), "message" => flash.message}
    if (flash.title != nil), do: Reflect.setField(result, "title", flash.title), else: nil
    if (flash.details != nil), do: Reflect.setField(result, "details", flash.details), else: nil
    if (flash.dismissible != nil), do: Reflect.setField(result, "dismissible", flash.dismissible), else: nil
    if (flash.timeout != nil), do: Reflect.setField(result, "timeout", flash.timeout), else: nil
    if (flash.action != nil), do: Reflect.setField(result, "action", flash.action), else: nil
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
    type = FlashTypeTools.fromString(Reflect.field(phoenix_flash, "type"))
    message = Reflect.field(phoenix_flash, "message")
    %{"type" => type, "message" => message, "title" => Reflect.field(phoenix_flash, "title"), "details" => Reflect.field(phoenix_flash, "details"), "dismissible" => Reflect.field(phoenix_flash, "dismissible"), "timeout" => Reflect.field(phoenix_flash, "timeout"), "action" => Reflect.field(phoenix_flash, "action")}
  end

  @doc """
    Extract error messages from Ecto changeset
    Helper function for validation error handling

    @param changeset Ecto changeset with errors
    @return Array<String> List of error messages
  """
  @spec extract_changeset_errors(term()) :: Array.t()
  def extract_changeset_errors(changeset) do
    errors = []
    changeset_errors = Reflect.field(changeset, "errors")
    if (changeset_errors != nil) do
      _g = 0
      _g = Reflect.fields(changeset_errors)
      Enum.map(_g, fn item -> field = Enum.at(_g, _g)
      _g = _g + 1
      field_errors = Reflect.field(changeset_errors, field)
      if (Std.isOfType(field_errors, Array)) do
        _g = 0
        _g = field_errors
        Enum.map(_g, fn item -> error = Enum.at(_g, _g)
        _g = _g + 1
        errors ++ ["" <> field <> ": " <> Std.string(error)] end)
      else
        errors ++ ["" <> field <> ": " <> field_errors]
      end end)
    end
    errors
  end

end
