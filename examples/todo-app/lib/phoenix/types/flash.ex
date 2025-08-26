defmodule Flash do
  @moduledoc """
    Flash module generated from Haxe

     * Type-safe flash message builder and utilities
  """

  # Static functions
  @doc "Generated from Haxe info"
  def info(message, title \\ nil) do
    %{"type" => :info, "message" => message, "title" => title, "dismissible" => true}
  end

  @doc "Generated from Haxe success"
  def success(message, title \\ nil) do
    %{"type" => :success, "message" => message, "title" => title, "dismissible" => true, "timeout" => 5000}
  end

  @doc "Generated from Haxe warning"
  def warning(message, title \\ nil) do
    %{"type" => :warning, "message" => message, "title" => title, "dismissible" => true}
  end

  @doc "Generated from Haxe error"
  def error(message, details \\ nil, title \\ nil) do
    %{"type" => :error, "message" => message, "details" => details, "title" => title, "dismissible" => true}
  end

  @doc "Generated from Haxe validationError"
  def validation_error(message, changeset) do
    errors = Flash.extract_changeset_errors(changeset)

    %{"type" => :error, "message" => message, "details" => errors, "title" => "Validation Failed", "dismissible" => true}
  end

  @doc "Generated from Haxe toPhoenixFlash"
  def to_phoenix_flash(flash) do
    result = %{"type" => FlashTypeTools.to_string(flash.type), "message" => flash.message}

    if ((flash.title != nil)) do
      Reflect.set_field(result, "title", flash.title)
    else
      nil
    end

    if ((flash.details != nil)) do
      Reflect.set_field(result, "details", flash.details)
    else
      nil
    end

    if ((flash.dismissible != nil)) do
      Reflect.set_field(result, "dismissible", flash.dismissible)
    else
      nil
    end

    if ((flash.timeout != nil)) do
      Reflect.set_field(result, "timeout", flash.timeout)
    else
      nil
    end

    if ((flash.action != nil)) do
      Reflect.set_field(result, "action", flash.action)
    else
      nil
    end

    result
  end

  @doc "Generated from Haxe fromPhoenixFlash"
  def from_phoenix_flash(phoenix_flash) do
    type = FlashTypeTools.from_string(Reflect.field(phoenix_flash, "type"))

    message = Reflect.field(phoenix_flash, "message")

    %{"type" => type, "message" => message, "title" => Reflect.field(phoenix_flash, "title"), "details" => Reflect.field(phoenix_flash, "details"), "dismissible" => Reflect.field(phoenix_flash, "dismissible"), "timeout" => Reflect.field(phoenix_flash, "timeout"), "action" => Reflect.field(phoenix_flash, "action")}
  end

  @doc "Generated from Haxe extractChangesetErrors"
  def extract_changeset_errors(changeset) do
    errors = []

    changeset_errors = Reflect.field(changeset, "errors")

    if ((changeset_errors != nil)) do
      g_counter = 0
      g_array = Reflect.fields(changeset_errors)
      Enum.filter(g1, fn item -> Std.is_of_type(item_errors, Array) end)
    else
      nil
    end

    errors
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
