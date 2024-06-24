require 'net/http'

DOMAIN = 'example.com'
CONFIG_ITEMS = [
  { host: "tls-12.#{DOMAIN}", port: 44_333 },
  { host: "tls-13.#{DOMAIN}", port: 44_334 }
].freeze

ca_file = 'tmp/test.crt'

CONFIG_ITEMS.each do |item|
  # require 'debug'
  # binding.break

  uri = URI("https://#{item[:host]}")
  begin
    Net::HTTP.start(item[:host],
                    item[:port],
                    use_ssl: true,
                    ca_file: ca_file) do |http|
      http.get(uri)
    end
  rescue StandardError => e
    puts "Failed to load from #{item[:host]}: #{e}"
  else
    puts "Loaded from #{item[:host]}"
  end
end
