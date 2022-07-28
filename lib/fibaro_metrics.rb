class FibaroMetrics
  attr_reader :client

  def initialize(client:)
    @client = client
  end

  def generate
    room_map = get_room_map

    devices = client.get_devices
    ts = current_timestamp

    power_parent_ids_stored = Set.new
    energy_parent_ids_stored = Set.new
    battery_parent_ids_stored = Set.new

    metrics = []
    devices.map do |device|
      room_id = device.roomID
      room = room_map[room_id]

      device_labels = {
        device_id: device.id,
        device_name: device.name,
        device_type: device.type,
        device_role: device.properties.deviceRole,
        parent_id: device.parentId,
        room_id: room_id,
        room_name: room&.name,
      }

      if device.type == "com.fibaro.temperatureSensor"
        metric = "fibaro_temperature"

        labels = device_labels.merge(
          unit: device.properties.unit,
        )
        value = device.properties.value

        metrics << Metric.new(metric, labels, value)
      end

      if device.type == "com.fibaro.lightSensor"
        metric = "fibaro_illuminance"

        labels = device_labels.merge(
          unit: device.properties.unit,
        )
        value = device.properties.value

        metrics << Metric.new(metric, labels, value)
      end

      if device.properties.power.is_a?(Numeric) && !power_parent_ids_stored.include?(device.parentId)
        power_parent_ids_stored << device.parentId

        metric = "fibaro_power"

        labels = device_labels.merge(
          unit: "W",
        )
        value = device.properties.power

        metrics << Metric.new(metric, labels, value)
      end

      if device.properties.energy.is_a?(Numeric) && !energy_parent_ids_stored.include?(device.parentId)
        energy_parent_ids_stored << device.parentId
        metric = "fibaro_energy"

        labels = device_labels.merge(
          unit: "kWh",
          is_light: device.properties.isLight || false
        )
        value = device.properties.energy

        metrics << Metric.new(metric, labels, value)
      end

      if device.type == "com.fibaro.FGR223"
        metrics << Metric.new("fibaro_blinds_level", device_labels.merge(
          unit: "%",
        ), device.properties.value)
        metrics << Metric.new("fibaro_blinds_position", device_labels.merge(
          unit: "%",
        ), device.properties.value2)
      end

      if device.type == "com.fibaro.yrWeather"
        metrics << Metric.new("fibaro_weather_humidity", device_labels.merge(
          unit: "%",
        ), device.properties.Humidity)
        metrics << Metric.new("fibaro_weather_pressure", device_labels.merge(
          unit: "hPa",
        ), device.properties.Pressure)
        metrics << Metric.new("fibaro_weather_temperature", device_labels.merge(
          unit: "C",
        ), device.properties.Temperature)
        metrics << Metric.new("fibaro_weather_wind", device_labels.merge(
          unit: "km/h",
        ), device.properties.Wind)
        metrics << Metric.new("fibaro_weather_#{device.properties.WeatherCondition}", device_labels.merge(
        ), 1)
      end

      if device.type == "com.fibaro.sonosSpeaker"
        metrics << Metric.new("fibaro_player_volume", device_labels.merge(
          unit: "%",
        ), device.properties.volume)
        metrics << Metric.new("fibaro_player_mute", device_labels.merge(
        ), device.properties.mute ? 1 : 0)
        metrics << Metric.new("fibaro_player_playing", device_labels.merge(
        ), device.properties.state == "PLAYING" ? 1 : 0)
      end

      if device.type == "com.fibaro.binarySwitch"
        metrics << Metric.new("fibaro_switch_value", device_labels.merge(
        ), device.properties.value ? 1 : 0)
      end

      if device.type == "com.fibaro.FGDW002"
        metrics << Metric.new("fibaro_door_sensor_value", device_labels.merge(
        ), device.properties.value ? 1 : 0)
        metrics << Metric.new("fibaro_door_sensor_tamper", device_labels.merge(
        ), device.properties.tamper ? 1 : 0)
        metrics << Metric.new("fibaro_door_sensor_last_breached", device_labels.merge(
        ), device.properties.lastBreached)
      end

      if device.type == "com.fibaro.FGMS001v2"
        metrics << Metric.new("fibaro_motion_sensor_value", device_labels.merge(
        ), device.properties.value ? 1 : 0)
        metrics << Metric.new("fibaro_motion_sensor_tamper", device_labels.merge(
        ), device.properties.tamper ? 1 : 0)
        metrics << Metric.new("fibaro_motion_sensor_last_breached", device_labels.merge(
        ), device.properties.lastBreached)
      end

      if device.type == "com.fibaro.seismometer"
        metrics << Metric.new("fibaro_seismic_sensor_value", device_labels.merge(
          unit: device.properties.unit,
        ), device.properties.value)
      end

      if device.properties.batteryLevel.is_a?(Numeric) && !battery_parent_ids_stored.include?(device.parentId)
        battery_parent_ids_stored << device.parentId

        metrics << Metric.new("fibaro_battery_level", device_labels.merge(
          unit: '%'
        ), device.properties.batteryLevel)
      end
    end

    metrics.map do |metric|
      "#{metric.metric}{#{serialize_labels(metric.labels)}} #{metric.value} #{ts}"
    end
  end

  class Metric < Struct.new(:metric, :labels, :value)
  end

  private

  def current_timestamp
    (Time.now.to_f * 1000).to_i
  end

  def get_room_map
    client.get_rooms.reduce({}) do |acc, room|
      acc[room.id] = room
      acc
    end
  end

  def serialize_labels(hash)
    hash
      .compact
      .map do |key, value|
      "#{key}=#{value.inspect}"
    end.join(',')
  end
end