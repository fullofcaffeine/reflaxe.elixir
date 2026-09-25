defmodule Reader do
  def read() do
    captured = &PrivateOnly.value/0
    instance = InstanceScope.new(17)
    Anchored.value() + Anchored.anchor() + captured.() + AccessScope.value() + InstanceScope.value(instance)
  end
end
