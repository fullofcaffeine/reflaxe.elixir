defmodule Flash do
  @moduledoc """
    Flash module generated from Haxe

     * Type-safe flash message builder and utilities
  """

  # Static functions
  @doc "Generated from Haxe info"
  def info(message, title \\ nil) do
    %{:type => :Info, :message => message, :title => title, :dismissible => true}
  end

  @doc "Generated from Haxe success"
  def success(message, title \\ nil) do
    %{:type => :Success, :message => message, :title => title, :dismissible => true, :timeout => 5000}
  end

  @doc "Generated from Haxe warning"
  def warning(message, title \\ nil) do
    %{:type => :Warning, :message => message, :title => title, :dismissible => true}
  end

  @doc "Generated from Haxe error"
  def error(message, details \\ nil, title \\ nil) do
    %{:type => :Error, :message => message, :details => details, :title => title, :dismissible => true}
  end

  @doc "Generated from Haxe validationError"
  def validation_error(message, changeset) do
    errors = :Flash.extractChangesetErrors(changeset)
    %{:type => :Error, :message => message, :details => errors, :title => "Validation Failed", :dismissible => true}
  end

  @doc "Generated from Haxe toPhoenixFlash"
  def to_phoenix_flash(flash) do
    %{:type => :FlashTypeTools.toString(flash.type), :message => flash.message, :title => flash.title, :details => flash.details, :dismissible => flash.dismissible, :timeout => flash.timeout, :action => flash.action}
  end

  @doc "Generated from Haxe fromPhoenixFlash"
  def from_phoenix_flash(phoenix_flash) do
    temp_string = nil
    temp_string_1 = nil
    temp_bool = nil

    temp_string = nil
    tmp = phoenix_flash.type
    if (tmp != nil) do
      temp_string = tmp
    else
      temp_string = "info"
    end
    flash_type = :FlashTypeTools.fromString(temp_string)
    temp_string_1 = nil
    tmp = phoenix_flash.message
    if (tmp != nil) do
      temp_string_1 = tmp
    else
      temp_string_1 = ""
    end
    temp_bool = nil
    tmp = phoenix_flash.dismissible
    if (tmp != nil) do
      temp_bool = tmp
    else
      temp_bool = true
    end
    %{:type => flash_type, :message => temp_string_1, :title => phoenix_flash.title, :details => phoenix_flash.details, :dismissible => temp_bool, :timeout => phoenix_flash.timeout, :action => phoenix_flash.action}
  end

  @doc "Generated from Haxe extractChangesetErrors"
  def extract_changeset_errors(_changeset) do
    []
  end

end
