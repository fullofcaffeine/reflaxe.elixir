defmodule Flash do
  def info(message, title) do
    %{:type => :info, :message => message, :title => title, :dismissible => true}
  end
  def success(message, title) do
    %{:type => :success, :message => message, :title => title, :dismissible => true, :timeout => 5000}
  end
  def warning(message, title) do
    %{:type => :warning, :message => message, :title => title, :dismissible => true}
  end
  def error(message, details, title) do
    %{:type => :error, :message => message, :details => details, :title => title, :dismissible => true}
  end
  def validation_error(message, changeset) do
    errors = extract_changeset_errors(changeset)
    %{:type => :error, :message => message, :details => errors, :title => "Validation Failed", :dismissible => true}
  end
  def to_phoenix_flash(flash) do
    %{:type => FlashTypeTools.to_string(flash.type), :message => flash.message, :title => flash.title, :details => flash.details, :dismissible => flash.dismissible, :timeout => flash.timeout, :action => flash.action}
  end
  def from_phoenix_flash(phoenix_flash) do
    tmp = phoenix_flash.type
    type_string = if tmp != nil, do: tmp, else: "info"
    flash_type = {:FromString, type_string}
    tmp = phoenix_flash.message
    message = if tmp != nil, do: tmp, else: ""
    %{:type => flash_type, :message => message, :title => phoenix_flash.title, :details => phoenix_flash.details, :dismissible => tmp = phoenix_flash.dismissible
if tmp != nil, do: tmp, else: true, :timeout => phoenix_flash.timeout, :action => phoenix_flash.action}
  end
  defp extract_changeset_errors(changeset) do
    []
  end
end