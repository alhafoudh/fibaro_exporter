class FibaroClient
  attr_reader :base_url
  attr_reader :username
  attr_reader :password
  attr_reader :client

  def initialize(base_url:, username:, password:)
    @base_url = base_url
    @username = username
    @password = password

    @client = Faraday.new(url: base_url) do |conn|
      conn.request :authorization, :basic, username, password
    end
  end

  def get_rooms
    get('/api/rooms')
  end

  def get_devices
    get('/api/devices')
  end

  def get_device(id)
    get("/api/devices/#{id}")
  end

  def self.build_from_env
    base_url = ENV.fetch('FIBARO_BASE_URL')
    username = ENV.fetch('FIBARO_USERNAME')
    password = ENV.fetch('FIBARO_PASSWORD')

    FibaroClient.new(
      base_url:,
      username:,
      password:,
    )
  end

  private

  def get(path)
    parse_response(client.get(path))
  end

  def parse_response(response)
    JSON.parse(response.body, object_class: OpenStruct)
  end
end
