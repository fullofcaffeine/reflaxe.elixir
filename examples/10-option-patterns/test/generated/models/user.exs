defmodule OptionPatterns.User do
  import Kernel, except: [to_string: 1], warn: false
  def new(id_param, name_param, email_param, active_param) do
    struct = %{:__reflaxe_class__ => OptionPatterns.User, :id => nil, :name => nil, :email => nil, :active => nil}
    struct = %{struct | id: id_param}
    struct = %{struct | name: name_param}
    struct = %{struct | email: email_param}
    struct = %{struct | active: active_param}
    struct
  end
  def get_display_name(struct) do
    if (struct.active) do
      struct.name
    else
      "#{struct.name} (inactive)"
    end
  end
  def has_valid_email(struct) do
    not Kernel.is_nil(struct.email) and (case :binary.match(struct.email, "@") do
  {pos, _} -> pos
  :nomatch -> -1
end) > 0
  end
  def to_string(struct) do
    "User(id=#{Reflaxe.Elixir.HaxeFloat.to_string(struct.id)}, name=\"#{struct.name}\", email=\"#{struct.email}\", active=#{Reflaxe.Elixir.HaxeFloat.to_string(struct.active)})"
  end
end
