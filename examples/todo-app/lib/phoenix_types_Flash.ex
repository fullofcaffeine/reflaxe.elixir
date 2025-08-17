defmodule FlashTypeTools do
  @moduledoc """
    FlashTypeTools module generated from Haxe

     * Helper functions for FlashType enum
  """

  # Static functions
  @doc """
    Convert FlashType to string for Phoenix compatibility

    @param type Flash type enum value
    @return String Phoenix-compatible string representation
  """
  @spec to_string(FlashType.t()) :: String.t()
  def to_string(type) do
    temp_result = nil
    case (elem(type, 0)) do
      0 ->
        temp_result = "info"
      1 ->
        temp_result = "success"
      2 ->
        temp_result = "warning"
      3 ->
        temp_result = "error"
    end
    temp_result
  end

  @doc """
    Parse string to FlashType

    @param str String representation of flash type
    @return FlashType Enum value, defaults to Info for unknown strings
  """
  @spec from_string(String.t()) :: FlashType.t()
  def from_string(str) do
    temp_result = nil
    _g = String.downcase(str)
    with "success" <- (_g) do
      temp_result = :success
    else
      "error" -> temp_result = :error
      _ -> temp_result = :info
    end
    temp_result
  end

  @doc """
    Get CSS class for flash type
    Standard Tailwind CSS classes for flash styling

    @param type Flash type enum value
    @return String CSS class string
  """
  @spec get_css_class(FlashType.t()) :: String.t()
  def get_css_class(type) do
    temp_result = nil
    case (elem(type, 0)) do
      0 ->
        temp_result = "bg-blue-50 border-blue-200 text-blue-800"
      1 ->
        temp_result = "bg-green-50 border-green-200 text-green-800"
      2 ->
        temp_result = "bg-yellow-50 border-yellow-200 text-yellow-800"
      3 ->
        temp_result = "bg-red-50 border-red-200 text-red-800"
    end
    temp_result
  end

  @doc """
    Get icon name for flash type
    Standard icon names for flash message display

    @param type Flash type enum value
    @return String Icon name (compatible with Heroicons or similar)
  """
  @spec get_icon_name(FlashType.t()) :: String.t()
  def get_icon_name(type) do
    temp_result = nil
    case (elem(type, 0)) do
      0 ->
        temp_result = "information-circle"
      1 ->
        temp_result = "check-circle"
      2 ->
        temp_result = "exclamation-triangle"
      3 ->
        temp_result = "x-circle"
    end
    temp_result
  end

end


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
    errors = Flash.extractChangesetErrors(changeset)
    %{"type" => :error, "message" => message, "details" => errors, "title" => "Validation Failed", "dismissible" => true}
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


defmodule FlashMapTools do
  @moduledoc """
    FlashMapTools module generated from Haxe

     * Utilities for working with Phoenix flash maps
  """

  # Static functions
  @doc """
    Check if flash map has any messages

    @param flashMap Phoenix flash map
    @return Bool True if any flash messages exist
  """
  @spec has_any(FlashMap.t()) :: boolean()
  def has_any(flash_map) do
    flash_map.info != nil || flash_map.success != nil || flash_map.warning != nil || flash_map.error != nil
  end

  @doc """
    Get all flash messages as structured array

    @param flashMap Phoenix flash map
    @return Array<FlashMessage> Array of structured flash messages
  """
  @spec get_all(FlashMap.t()) :: Array.t()
  def get_all(flash_map) do
    messages = []
    if (flash_map.info != nil), do: messages ++ [Flash.info(flash_map.info)], else: nil
    if (flash_map.success != nil), do: messages ++ [Flash.success(flash_map.success)], else: nil
    if (flash_map.warning != nil), do: messages ++ [Flash.warning(flash_map.warning)], else: nil
    if (flash_map.error != nil), do: messages ++ [Flash.error(flash_map.error)], else: nil
    messages
  end

  @doc """
    Clear all flash messages

    @return FlashMap Empty flash map
  """
  @spec clear() :: FlashMap.t()
  def clear() do
    %{}
  end

end


defmodule FlashType do
  @moduledoc """
  FlashType enum generated from Haxe
  
  
 * Standard flash message types used in Phoenix applications
 * 
 * These correspond to common CSS classes and UI patterns:
 * - Info: Blue, informational messages
 * - Success: Green, confirmation messages  
 * - Warning: Yellow, caution messages
 * - Error: Red, error messages
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :info |
    :success |
    :warning |
    :error

  @doc "Creates info enum value"
  @spec info() :: :info
  def info(), do: :info

  @doc "Creates success enum value"
  @spec success() :: :success
  def success(), do: :success

  @doc "Creates warning enum value"
  @spec warning() :: :warning
  def warning(), do: :warning

  @doc "Creates error enum value"
  @spec error() :: :error
  def error(), do: :error

  # Predicate functions for pattern matching
  @doc "Returns true if value is info variant"
  @spec is_info(t()) :: boolean()
  def is_info(:info), do: true
  def is_info(_), do: false

  @doc "Returns true if value is success variant"
  @spec is_success(t()) :: boolean()
  def is_success(:success), do: true
  def is_success(_), do: false

  @doc "Returns true if value is warning variant"
  @spec is_warning(t()) :: boolean()
  def is_warning(:warning), do: true
  def is_warning(_), do: false

  @doc "Returns true if value is error variant"
  @spec is_error(t()) :: boolean()
  def is_error(:error), do: true
  def is_error(_), do: false

end
