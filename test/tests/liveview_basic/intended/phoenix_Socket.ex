@typedoc """

 * Socket configuration options
 
"""
@type socket_options :: %{
  optional(:binary_type) => String.t() | nil,
  optional(:heartbeat_interval_ms) => integer() | nil,
  optional(:logger) => any() | nil,
  optional(:longpoller_timeout) => integer() | nil,
  optional(:params) => any() | nil,
  optional(:reconnect_after_ms) => any() | nil,
  optional(:rejoin_after_ms) => any() | nil,
  optional(:timeout) => integer() | nil,
  optional(:transport) => any() | nil,
  optional(:vsn) => String.t() | nil
}