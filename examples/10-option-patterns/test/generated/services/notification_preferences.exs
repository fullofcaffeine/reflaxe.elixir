defmodule OptionPatterns.NotificationPreferences do
  def new(email_enabled_param, sms_enabled_param, push_enabled_param) do
    struct = %{:__reflaxe_class__ => OptionPatterns.NotificationPreferences, :email_enabled => nil, :sms_enabled => nil, :push_enabled => nil}
    struct = %{struct | email_enabled: email_enabled_param}
    struct = %{struct | sms_enabled: sms_enabled_param}
    struct = %{struct | push_enabled: push_enabled_param}
    struct
  end
  def is_allowed(struct, type) do
    (case type do
      {:email} -> struct.email_enabled
      {:sms} -> struct.sms_enabled
      {:push} -> struct.push_enabled
    end)
  end
end
