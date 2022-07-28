require 'bundler'
Bundler.require

require_relative 'lib/fibaro_client'
require_relative 'lib/fibaro_metrics'

Dotenv.load

class FibaroExporter
  def call(env)
    status = 200
    headers = { "Content-Type" => "text/plain; charset=utf-8" }

    generator = FibaroMetrics.new(client: FibaroClient.build_from_env)
    metrics = generator.generate
    body = [metrics.join("\n")]

    [status, headers, body]
  end
end

run FibaroExporter.new