package phoenix_chat_hx.infrastructure;

/**
 * Typed wrapper for DNSCluster child spec module.
 */
@:native("DNSCluster")
@:unsafeExtern // Intentional app-level extern boundary for pure Elixir module interop.
extern class DNSCluster {}
