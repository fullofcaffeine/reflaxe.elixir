defmodule PhoenixChat.ChatStateTest do
  use ExUnit.Case
  test "append message returns new array and appends" do
    original = %{:id => 1, :user_id => "u1", :user_name => "alice", :body => "hello", :at => 1, :row_class => "msg"}
    next = %{:id => 2, :user_id => "u2", :user_name => "bob", :body => "world", :at => 2, :row_class => "msg"}
    current = [original]
    updated = PhoenixChat.ChatState.append_message(current, next)
    actual = length(current)
    assert actual == 1
    actual = length(updated)
    assert actual == 2
    actual = Enum.at(updated, 1).body
    assert actual == "world"
  end
end
