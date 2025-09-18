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
    if (Map.get(phoenixFlash, :type) != nil) do
      temp_maybe_string = phoenixFlash.type
    else
      temp_maybe_string = "info"
    end
    flash_type = FlashTypeTools.from_string(tempMaybeString)
    temp_maybe_string1 = nil
    if (Map.get(phoenixFlash, :message) != nil) do
      temp_maybe_string1 = phoenixFlash.message
    else
      temp_maybe_string1 = ""
    end
    temp_maybe_bool = nil
    if (Map.get(phoenixFlash, :dismissible) != nil) do
      temp_maybe_bool = phoenixFlash.dismissible
    else
      temp_maybe_bool = true
    end
    %{:type => flashType, :message => tempMaybeString1, :title => phoenixFlash.title, :details => phoenixFlash.details, :dismissible => tempMaybeBool, :timeout => phoenixFlash.timeout, :action => phoenixFlash.action}
  end
  defp extract_changeset_errors(changeset) do
    []
  end
end