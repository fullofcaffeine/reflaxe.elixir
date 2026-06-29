defmodule Main do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Main, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Main, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def manifest() do
    __haxe_static_get__(:manifest, "protocol ProfileHookEvent\ncompanion ProfileHookEvents\nevent hook ClipboardCopied clipboard_copied (message:String->message:string)\nevent hook Ping ping ()\nevent hook TagsChanged tags_changed (tags:Array<String>->tags:string_array)\nevent hook TodoSelected todo_selected (todoId:Int->todo_id:int, fromHook:Bool->from_hook:bool)\n")
  end
  def manifest(value) do
    __haxe_static_put__(:manifest, value)
  end
  def hash() do
    __haxe_static_get__(:hash, "25fd7064d0904d51f48edae81da73bfc27ebf621")
  end
  def hash(value) do
    __haxe_static_put__(:hash, value)
  end
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  def main() do
    _ = assert_that(:binary.match(Main.manifest(), "protocol ProfileHookEvent") != :nomatch, "protocol name missing")
    _ = assert_that(:binary.match(Main.manifest(), "companion ProfileHookEvents") != :nomatch, "companion name missing")
    _ = assert_that(:binary.match(Main.manifest(), "event hook ClipboardCopied clipboard_copied (message:String->message:string)") != :nomatch, "clipboard event missing")
    _ = assert_that(:binary.match(Main.manifest(), "event hook Ping ping ()") != :nomatch, "ping event missing")
    _ = assert_that(:binary.match(Main.manifest(), "event hook TodoSelected todo_selected (todoId:Int->todo_id:int, fromHook:Bool->from_hook:bool)") != :nomatch, "multi-field event missing")
    _ = assert_that(:binary.match(Main.manifest(), "event hook TagsChanged tags_changed (tags:Array<String>->tags:string_array)") != :nomatch, "array field missing")
    _ = assert_that(String.length(Main.hash()) == 40, "manifest hash should be sha1")
  end
end
