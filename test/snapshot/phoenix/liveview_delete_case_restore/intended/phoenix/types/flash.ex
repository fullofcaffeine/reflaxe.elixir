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
    errors = extract_changeset_errors(changeset)
    %{:type => {:error}, :message => message, :details => errors, :title => "Validation Failed", :dismissible => true}
  end
  def to_phoenix_flash(flash) do
    %{:type => MyApp.FlashTypeTools.to_string(flash.type), :message => flash.message, :title => flash.title, :details => flash.details, :dismissible => flash.dismissible, :timeout => flash.timeout, :action => flash.action}
  end
  def from_phoenix_flash(phoenix_flash) do
    type_string = if (not Kernel.is_nil(phoenix_flash.type)), do: phoenix_flash.type, else: "info"
    flash_type = MyApp.FlashTypeTools.from_string(type_string)
    message = if (not Kernel.is_nil(phoenix_flash.message)), do: phoenix_flash.message, else: ""
    %{:type => flash_type, :message => message, :title => phoenix_flash.title, :details => phoenix_flash.details, :dismissible => (if (not Kernel.is_nil(phoenix_flash.dismissible)), do: phoenix_flash.dismissible, else: true), :timeout => phoenix_flash.timeout, :action => phoenix_flash.action}
  end
  defp extract_changeset_errors(changeset) do
    if (Kernel.is_nil(changeset) or Kernel.is_nil(changeset.errors)), do: [], else: Enum.map(changeset.errors, (fn -> fn err ->
    field = err.field
    text = if (not Kernel.is_nil(err.message)), do: err.message.text, else: ""
    "" <> field <> ": " <> text
  end end).())
  end
end
