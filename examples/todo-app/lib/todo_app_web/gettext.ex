defmodule TodoAppWeb.Gettext do
  def gettext(msgid, bindings) do
    fn msgid, bindings -> msgid end
  end
  def dgettext(domain, msgid, bindings) do
    fn domain, msgid, bindings -> msgid end
  end
  def ngettext(msgid, msgid_plural, count, bindings) do
    fn msgid, msgid_plural, count, bindings -> if (count == 1) do
  msgid
else
  msgid_plural
end end
  end
  def dngettext(domain, msgid, msgid_plural, count, bindings) do
    fn domain, msgid, msgid_plural, count, bindings -> if (count == 1) do
  msgid
else
  msgid_plural
end end
  end
  def get_locale() do
    fn -> "en" end
  end
  def put_locale(locale) do
    fn locale -> nil end
  end
  def known_locales() do
    fn -> ["en", "es", "fr", "de", "pt", "ja", "zh"] end
  end
end