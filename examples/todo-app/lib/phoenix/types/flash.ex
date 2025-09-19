defmodule Flash do
  def info(message, title) do
    %{:type => {:info}, :message => message, :title => title, :dismissible => true}
  end
  def success(message, title) do
    %{:type => {:success}, :message => message, :title => title, :dismissible => true, :timeout => 5000}
  end
  def warning(message, title) do
    %{:type => {:warning}, :message => message, :title => title, :dismissible => true}
  end
  def error(message, details, title) do
    %{:type => {:error}, :message => message, :details => details, :title => title, :dismissible => true}
  end
  def validation_error(message, changeset) do
    %{:type => {:error}, :message => message, :details => (Flash.extract_changeset_errors(changeset)), :title => "Validation Failed", :dismissible => true}
  end
  def to_phoenix_flash(flash) do
    %{:type => FlashTypeTools.to_string(flash.type), :message => flash.message, :title => flash.title, :details => flash.details, :dismissible => flash.dismissible, :timeout => flash.timeout, :action => flash.action}
  end
  def from_phoenix_flash(phoenix_flash) do
    temp_maybe_string = nil
    if (phoenix_flash.type != nil) do
      temp_maybe_string = phoenix_flash.type
    else
      temp_maybe_string = "info"
    end
    flash_type = FlashTypeTools.from_string(temp_maybe_string)
    temp_maybe_string1 = nil
    if (phoenix_flash.message != nil) do
      temp_maybe_string1 = phoenix_flash.message
    else
      temp_maybe_string1 = ""
    end
    temp_maybe_bool = nil
    if (phoenix_flash.dismissible != nil) do
      temp_maybe_bool = phoenix_flash.dismissible
    else
      temp_maybe_bool = true
    end
    %{:type => flash_type, :message => temp_maybe_string1, :title => phoenix_flash.title, :details => phoenix_flash.details, :dismissible => temp_maybe_bool, :timeout => phoenix_flash.timeout, :action => phoenix_flash.action}
  end
  defp extract_changeset_errors(changeset) do
    []
  end
end