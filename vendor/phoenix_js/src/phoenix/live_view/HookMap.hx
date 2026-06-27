package phoenix.live_view;

import haxe.DynamicAccess;

/**
 * Typed Phoenix LiveView hook registry map.
 *
 * Phoenix's JavaScript API expects a plain object keyed by hook name. The
 * DynamicAccess representation is isolated here so application code can pass a
 * named HookMap instead of exposing the dynamic JS object shape directly.
 */
abstract HookMap(DynamicAccess<Hook>) to DynamicAccess<Hook> {
  public inline function new()
    this = new DynamicAccess<Hook>();

  public inline function set(name:String, hook:Hook):Hook
    return this.set(name, hook);
}
