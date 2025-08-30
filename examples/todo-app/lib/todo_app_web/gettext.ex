defmodule TodoAppWeb.Gettext do
  def gettext(msgid, bindings) do
    msgid
  end
  def dgettext(domain, msgid, bindings) do
    msgid
  end
  def ngettext(msgid, msgid_plural, count, bindings) do
    if (count == 1) do
      msgid
    else
      msgid_plural
    end
  end
  def dngettext(domain, msgid, msgid_plural, count, bindings) do
    if (count == 1) do
      msgid
    else
      msgid_plural
    end
  end
  def get_locale() do
    "en"
  end
  def put_locale(locale) do
    nil
  end
  def known_locales() do
    ["en", "es", "fr", "de", "pt", "ja", "zh"]
  end
end