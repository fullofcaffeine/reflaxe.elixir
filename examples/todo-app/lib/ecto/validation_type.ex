defmodule Ecto.ValidationType do
  def required() do
    {:Required}
  end
  def length(arg0, arg1) do
    {:Length, arg0, arg1}
  end
  def format(arg0) do
    {:Format, arg0}
  end
  def inclusion(arg0) do
    {:Inclusion, arg0}
  end
  def exclusion(arg0) do
    {:Exclusion, arg0}
  end
  def number(arg0, arg1) do
    {:Number, arg0, arg1}
  end
  def acceptance() do
    {:Acceptance}
  end
  def confirmation() do
    {:Confirmation}
  end
  def custom(arg0) do
    {:Custom, arg0}
  end
end