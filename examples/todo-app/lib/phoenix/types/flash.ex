defmodule Flash do
  def info() do
    fn message, title -> %{:type => :Info, :message => message, :title => title, :dismissible => true} end
  end
  def success() do
    fn message, title -> %{:type => :Success, :message => message, :title => title, :dismissible => true, :timeout => 5000} end
  end
  def warning() do
    fn message, title -> %{:type => :Warning, :message => message, :title => title, :dismissible => true} end
  end
  def error() do
    fn message, details, title -> %{:type => :Error, :message => message, :details => details, :title => title, :dismissible => true} end
  end
  def validationError() do
    fn message, changeset -> errors = Flash.extract_changeset_errors(changeset)
%{:type => :Error, :message => message, :details => errors, :title => "Validation Failed", :dismissible => true} end
  end
  def toPhoenixFlash() do
    fn flash -> %{:type => FlashTypeTools.to_string(flash.type), :message => flash.message, :title => flash.title, :details => flash.details, :dismissible => flash.dismissible, :timeout => flash.timeout, :action => flash.action} end
  end
  def fromPhoenixFlash() do
    fn phoenix_flash -> type_string = tmp = phoenix_flash.type
if (tmp != nil) do
  tmp
else
  "info"
end
flash_type = {:unknown, type_string}
message = tmp = phoenix_flash.message
if (tmp != nil) do
  tmp
else
  ""
end
%{:type => flash_type, :message => message, :title => phoenix_flash.title, :details => phoenix_flash.details, :dismissible => tmp = phoenix_flash.dismissible
if (tmp != nil) do
  tmp
else
  true
end, :timeout => phoenix_flash.timeout, :action => phoenix_flash.action} end
  end
  defp extractChangesetErrors() do
    fn changeset -> [] end
  end
end