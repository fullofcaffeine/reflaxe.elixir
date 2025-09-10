defmodule Flash do
  def info(message, title) do
    %{:type => {:Info}, :message => message, :title => title, :dismissible => true}
  end
  def success(message, title) do
    %{:type => {:Success}, :message => message, :title => title, :dismissible => true, :timeout => 5000}
  end
  def warning(message, title) do
    %{:type => {:Warning}, :message => message, :title => title, :dismissible => true}
  end
  def error(message, details, title) do
    %{:type => {:Error}, :message => message, :details => details, :title => title, :dismissible => true}
  end
  def validation_error(message, _changeset) do
    %{:type => {:Error}, :message => message, :details => (extract_changeset_errors(changeset)), :title => "Validation Failed", :dismissible => true}
  end
  def to_phoenix_flash(_flash) do
    %{:type => FlashTypeTools.to_string(flash.type), :message => flash.message, :title => flash.title, :details => flash.details, :dismissible => flash.dismissible, :timeout => flash.timeout, :action => flash.action}
  end
  def from_phoenix_flash(_phoenix_flash) do
    type_string = if (Map.get(phoenix_flash, :type) != nil), do: phoenix_flash.type, else: "info"
    flash_type = FlashTypeTools.from_string(type_string)
    message = if (Map.get(phoenix_flash, :message) != nil), do: phoenix_flash.message, else: ""
    %{:type => flash_type, :message => message, :title => phoenix_flash.title, :details => phoenix_flash.details, :dismissible => (if (Map.get(phoenix_flash, :dismissible) != nil), do: phoenix_flash.dismissible, else: true), :timeout => phoenix_flash.timeout, :action => phoenix_flash.action}
  end
  defp extract_changeset_errors(_changeset) do
    []
  end
end