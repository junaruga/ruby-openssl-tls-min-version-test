require 'net/http'

DOMAIN = 'example.com'

hosts = [
  "tls-10.#{DOMAIN}",
  "tls-11.#{DOMAIN}",
  "tls-12.#{DOMAIN}",
  "tls-13.#{DOMAIN}",
]

ca_file = 'tmp/test.crt'

hosts.each do |host|
  uri = URI("https://#{host}")
  begin
    Net::HTTP.start(host, 443, use_ssl: true, ca_file: ca_file) do |http|
      http.get(uri)
    end
  rescue StandardError => e
    puts "Failed to load from #{host}: #{e}"
  else
    puts "Loaded from #{host}"
  end
end
