require 'bundler'
Bundler.require

require_relative 'lib/fibaro_client'
require_relative 'lib/fibaro_metrics'

Dotenv.load

generator = FibaroMetrics.new(client: FibaroClient.build_from_env)
metrics = generator.generate
output = metrics.join("\n")

puts output
