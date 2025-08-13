@typedoc """

 * LiveSocket configuration options
 
"""
@type live_socket_options :: %{
  optional(:heartbeat_interval_ms) => integer() | nil,
  optional(:hooks) => any() | nil,
  optional(:logger) => any() | nil,
  optional(:logger_write_fn) => any() | nil,
  optional(:long_poll_fallback_ms) => integer() | nil,
  optional(:metadata) => any() | nil,
  optional(:params) => any() | nil,
  optional(:reconnect_after_ms) => any() | nil,
  optional(:rejoin_after_ms) => any() | nil,
  optional(:timeout) => integer() | nil,
  optional(:uploaders) => any() | nil,
  optional(:vsn) => String.t() | nil
}