defmodule TodoAppWeb.Gettext do
  def gettext() do
    fn msgid, bindings -> msgid end
  end
  def dgettext() do
    fn domain, msgid, bindings -> msgid end
  end
  def ngettext() do
    fn msgid, msgid_plural, count, bindings -> if (count == 1) do
  msgid
else
  msgid_plural
end end
  end
  def dngettext() do
    fn domain, msgid, msgid_plural, count, bindings -> if (count == 1) do
  msgid
else
  msgid_plural
end end
  end
  def get_locale() do
    fn -> "en" end
  end
  def put_locale() do
    fn locale -> nil end
  end
  def known_locales() do
    fn -> ["en", "es", "fr", "de", "pt", "ja", "zh"] end
  end
end