defmodule Flash do
  def info(message, title) do
    %{type: {:info}, message: message, title: title, dismissible: true}
  end
  def success(message, title) do
    %{type: {:success}, message: message, title: title, dismissible: true, timeout: 5000}
  end
  def warning(message, title) do
    %{type: {:warning}, message: message, title: title, dismissible: true}
  end
  def error(message, details, title) do
    %{type: {:error}, message: message, details: details, title: title, dismissible: true}
  end
  def validation_error(message, changeset) do
    errors = extract_changeset_errors(changeset)
    %{type: {:error}, message: message, details: errors, title: "Validation Failed", dismissible: true}
  end
  def to_phoenix_flash(flash) do
    %{type: FlashTypeTools.to_string(flash.type), message: flash.message, title: Map.get(flash, :title), details: Map.get(flash, :details), dismissible: Map.get(flash, :dismissible), timeout: Map.get(flash, :timeout), action: Map.get(flash, :action)}
  end
  def from_phoenix_flash(phoenix_flash) do
    type_string = if (not Kernel.is_nil(Map.get(phoenix_flash, :type))) do
      Map.get(phoenix_flash, :type)
    else
      "info"
    end
    flash_type = FlashTypeTools.from_string(type_string)
    message = if (not Kernel.is_nil(Map.get(phoenix_flash, :message))) do
      Map.get(phoenix_flash, :message)
    else
      ""
    end
    %{type: flash_type, message: message, title: Map.get(phoenix_flash, :title), details: Map.get(phoenix_flash, :details), dismissible: (if (not Kernel.is_nil(Map.get(phoenix_flash, :dismissible))) do
      Map.get(phoenix_flash, :dismissible)
    else
      true
    end), timeout: Map.get(phoenix_flash, :timeout), action: Map.get(phoenix_flash, :action)}
  end
  defp extract_changeset_errors(changeset) do
    if (Kernel.is_nil(changeset) or Kernel.is_nil(Map.get(changeset, :errors))) do
      []
    else
      Enum.map(Map.get(changeset, :errors), fn err ->
        field = err.field
        text = if (not Kernel.is_nil(err.message)), do: err.message.text, else: ""
        "" <> field <> ": " <> text
      end)
    end
  end
end
