require 'json'
require 'net/http'

class Bgplay
  class << self
    def get(prefix)
      data = JSON.parse(Net::HTTP.get(URI(url(prefix))))
      data = data['data']['initial_state']
      data.map {|d|
        {aspath: d['path'], community: d['community']}
      }
    end

    def url(prefix)
      "https://stat.ripe.net/data/bgplay/data.json?resource=#{prefix.sub(/\//, '%2F')}"
    end
  end
end
