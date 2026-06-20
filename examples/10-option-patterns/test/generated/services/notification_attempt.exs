defmodule OptionPatterns.NotificationAttempt do
  def new(user_id_param, result_param) do
    struct = %{:__reflaxe_class__ => OptionPatterns.NotificationAttempt, :user_id => nil, :result => nil}
    struct = %{struct | user_id: user_id_param}
    struct = %{struct | result: result_param}
    struct
  end
end
