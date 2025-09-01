defmodule Content do
  def text(arg0) do
    {:Text, arg0}
  end
  def number(arg0) do
    {:Number, arg0}
  end
  def empty() do
    {:Empty}
  end
end