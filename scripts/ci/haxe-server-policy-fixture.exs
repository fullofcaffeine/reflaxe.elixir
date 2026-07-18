defmodule HaxeServerPolicyFixture do
  @moduledoc false

  def run do
    previous_no_server = System.get_env("HAXE_NO_SERVER")
    previous_autostart = System.get_env("HAXE_SERVER_AUTOSTART")

    try do
      System.delete_env("HAXE_NO_SERVER")
      System.delete_env("HAXE_SERVER_AUTOSTART")

      assert_equal(HaxeServer.should_autostart?(:dev), false, "unset dev policy")
      assert_equal(HaxeServer.should_autostart?(:test), false, "unset test policy")
      assert_equal(HaxeServer.should_autostart?(:prod), false, "unset production policy")

      System.put_env("HAXE_SERVER_AUTOSTART", "dev")
      assert_equal(HaxeServer.should_autostart?(:dev), true, "explicit dev policy")
      assert_equal(HaxeServer.should_autostart?(:test), false, "dev policy outside dev")

      System.put_env("HAXE_SERVER_AUTOSTART", " ALWAYS ")
      assert_equal(HaxeServer.should_autostart?(:test), true, "normalized always policy")

      System.put_env("HAXE_SERVER_AUTOSTART", "never")
      assert_equal(HaxeServer.should_autostart?(:dev), false, "explicit never policy")

      System.put_env("HAXE_SERVER_AUTOSTART", "invalid")
      assert_equal(HaxeServer.should_autostart?(:dev), false, "invalid policy")

      System.put_env("HAXE_SERVER_AUTOSTART", "always")
      System.put_env("HAXE_NO_SERVER", "1")
      assert_equal(HaxeServer.should_autostart?(:dev), false, "no-server override")

      assert_equal(Mix.Tasks.Haxe.Watch.server_mode(once: true), :direct, "watch --once")
      assert_equal(Mix.Tasks.Haxe.Watch.server_mode(once: false), :managed, "watch mode")
      assert_equal(Mix.Tasks.Haxe.Watch.server_mode([]), :managed, "default watch mode")

      IO.puts("HAXE_SERVER_POLICY_FIXTURE:PASS")
    after
      restore_env("HAXE_NO_SERVER", previous_no_server)
      restore_env("HAXE_SERVER_AUTOSTART", previous_autostart)
    end
  end

  defp assert_equal(actual, expected, label) do
    if actual != expected do
      raise "#{label}: expected #{inspect(expected)}, got #{inspect(actual)}"
    end
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)
end

HaxeServerPolicyFixture.run()
