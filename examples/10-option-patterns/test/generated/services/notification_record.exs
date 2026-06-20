defmodule OptionPatterns.NotificationRecord do
  def new(user_id_param, message_param, type_param, timestamp_param, delivered_param) do
    struct = %{:__reflaxe_class__ => OptionPatterns.NotificationRecord, :user_id => nil, :message => nil, :type => nil, :timestamp => nil, :delivered => nil}
    struct = %{struct | user_id: user_id_param}
    struct = %{struct | message: message_param}
    struct = %{struct | type: type_param}
    struct = %{struct | timestamp: timestamp_param}
    struct = %{struct | delivered: delivered_param}
    struct
  end
end
