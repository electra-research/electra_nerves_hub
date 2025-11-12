import Config

# Do not print debug messages in production
config :logger, level: :info, backends: [:console, Sentry.LoggerBackend]

config :phoenix, logger: false

##
# NervesHub Web
#
config :nerves_hub, NervesHubWeb.Endpoint,
  server: true,
  force_ssl: [rewrite_on: [:x_forwarded_proto]]

##
# NervesHub Device
#
config :nerves_hub, NervesHubWeb.DeviceEndpoint, server: true

##
# Database and Oban
#
config :nerves_hub, NervesHub.Repo, pool_size: 20

config :nerves_hub, NervesHub.ObanRepo, pool_size: 10

# S3
config :ex_aws, :s3,
  access_key_id: System.get_env("S3_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("S3_SECRET_ACCESS_KEY"),
  bucket: System.get_env("S3_BUCKET_NAME"),
  host: System.get_env("S3_HOST")
