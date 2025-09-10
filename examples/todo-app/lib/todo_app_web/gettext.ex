defmodule TodoAppWeb.Gettext do
  @default_locale nil
  def gettext(msgid, _bindings) do
    msgid
  end
  def dgettext(_domain, msgid, _bindings) do
    msgid
  end
  def ngettext(msgid, msgid_plural, count, _bindings) do
    if (count == 1), do: msgid, else: msgid_plural
  end
  def dngettext(_domain, msgid, msgid_plural, count, _bindings) do
    if (count == 1), do: msgid, else: msgid_plural
  end
  def get_locale() do
    "en"
  end
  def put_locale(_locale) do
    nil
  end
  def known_locales() do
    ["en", "es", "fr", "de", "pt", "ja", "zh"]
  end
end