defmodule SimpleModulesTest do
  use ExUnit.Case

  test "basic module functions run from generated Elixir" do
    assert BasicModule.hello() == "world"
    assert BasicModule.greet("Ada") == "Hello, Ada!"
    assert BasicModule.calculate(7, 5, "add") == 12
    assert BasicModule.calculate(7, 5, "subtract") == 2
    assert BasicModule.calculate(7, 5, "multiply") == 35
    assert BasicModule.calculate(10, 2, "divide") == 5
    assert BasicModule.calculate(10, 0, "divide") == 0
    assert BasicModule.calculate(10, 2, "unknown") == 0
    assert BasicModule.get_timestamp() == "2024-01-01T00:00:00Z"
    assert BasicModule.is_valid("value")
    refute BasicModule.is_valid("")
  end

  test "math helper composition functions preserve expected values" do
    assert MathHelper.process_number(5.0) == 20
    assert MathHelper.calculate_discount(100.0, "premium") == 72
    assert MathHelper.calculate_discount(100.0, "regular") == 86
    assert MathHelper.calculate_discount(2.0, "guest") == 5
    assert MathHelper.format_user_name("  ADA LOVELACE ") == "Ada lovelace"
    assert MathHelper.validate_and_process("safe<input") == "Processed: safeinput"
  end

  test "user utility public API uses private helpers" do
    user = UserUtil.create_user("  ada lovelace  ", "  ADA@EXAMPLE.COM  ")

    assert user.name == "Ada Lovelace"
    assert user.email == "ada@example.com"
    assert user.created_at == "2024-01-01T00:00:00Z"
    assert String.starts_with?(user.id, "user_")

    updated = UserUtil.update_user(user, "grace hopper", "GRACE@EXAMPLE.COM")
    assert updated.name == "Grace Hopper"
    assert updated.email == "grace@example.com"
    assert updated.id == user.id

    assert UserUtil.format_user_for_display(updated) == "Grace H. (gr****@example.com)"
  end

  test "user utility rejects invalid create inputs" do
    assert_raise Reflaxe.Elixir.HaxeThrow, fn ->
      UserUtil.create_user("", "ada@example.com")
    end

    assert_raise Reflaxe.Elixir.HaxeThrow, fn ->
      UserUtil.create_user("Ada", "invalid-email")
    end
  end
end
