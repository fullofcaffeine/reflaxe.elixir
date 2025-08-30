defmodule Flash do
  def info(message, title) do
    %{:type => :Info, :message => message, :title => title, :dismissible => true}
  end
  def success(message, title) do
    %{:type => :Success, :message => message, :title => title, :dismissible => true, :timeout => 5000}
  end
  def warning(message, title) do
    %{:type => :Warning, :message => message, :title => title, :dismissible => true}
  end
  def error(message, details, title) do
    %{:type => :Error, :message => message, :details => details, :title => title, :dismissible => true}
  end
  def validationError(message, changeset) do
    errors = Flash.extract_changeset_errors(changeset)
    %{:type => :Error, :message => message, :details => errors, :title => "Validation Failed", :dismissible => true}
  end
  def toPhoenixFlash(flash) do
    %{:type => FlashTypeTools.to_string(flash.type), :message => flash.message, :title => flash.title, :details => flash.details, :dismissible => flash.dismissible, :timeout => flash.timeout, :action => flash.action}
  end
  def fromPhoenixFlash(phoenix_flash) do
    type_string = if (tmp = phoenix_flash.type) != nil, do: tmp, else: "info"
    flash_type = {:unknown, type_string}
    message = if (tmp = phoenix_flash.message) != nil, do: tmp, else: ""
    %{:type => flash_type, :message => message, :title => phoenix_flash.title, :details => phoenix_flash.details, :dismissible => (if (tmp = phoenix_flash.dismissible) != nil, do: tmp, else: true), :timeout => phoenix_flash.timeout, :action => phoenix_flash.action}
  end
  defp extractChangesetErrors(changeset) do
    []
  end
end