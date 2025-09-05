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
    errors = Phoenix.Flash.extract_changeset_errors(changeset)
    %{:type => :error, :message => message, :details => errors, :title => "Validation Failed", :dismissible => true}
  end
  def to_phoenix_flash(flash) do
    %{:type => Phoenix.FlashTypeTools.to_string(flash.type), :message => flash.message, :title => flash.title, :details => flash.details, :dismissible => flash.dismissible, :timeout => flash.timeout, :action => flash.action}
  end
  def from_phoenix_flash(phoenix_flash) do
    type_string = if (phoenix_flash.type != nil), do: phoenix_flash.type, else: "info"
    flash_type = Phoenix.FlashTypeTools.from_string(type_string)
    message = if (phoenix_flash.message != nil), do: phoenix_flash.message, else: ""
    %{:type => flash_type, :message => message, :title => phoenix_flash.title, :details => phoenix_flash.details, :dismissible => (if (phoenix_flash.dismissible != nil), do: phoenix_flash.dismissible, else: true), :timeout => phoenix_flash.timeout, :action => phoenix_flash.action}
  end
  defp extract_changeset_errors(_changeset) do
    []
  end
end