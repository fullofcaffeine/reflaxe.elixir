defmodule CustomException do
  def new(message, code) do
    %{:code => code}
  end
end