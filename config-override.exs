import Config

config :pleroma, :instance,
  registrations_open: false

config :prometheus, Pleroma.Web.Endpoint.MetricsExporter,
  enabled: true,
  auth: {:basic, "prometheus", "zcEHi6KZF372cC4G"},
  ip_whitelist: ["127.0.0.1"],
  path: "/api/pleroma/app_metrics",
  format: :text
