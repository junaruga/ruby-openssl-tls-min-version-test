require 'net/http'
require 'test/unit'

DOMAIN = 'example.com'
CONFIG_ITEMS = {
  tls_1_2: { host: "tls-12.#{DOMAIN}", port: 44_333 },
  tls_1_3: { host: "tls-13.#{DOMAIN}", port: 44_334 }
}.freeze
CA_FILE = 'tmp/test.crt'

class TestRubyOpenSSLTLSMin < Test::Unit::TestCase
  def test_with_tls_1_2_server
    # The connection to the TLS 1.2 server should fail.
    assert_raise(OpenSSL::SSL::SSLError) do
      connect_with_openssl_s_client(CONFIG_ITEMS[:tls_1_2][:host],
                                    CONFIG_ITEMS[:tls_1_2][:port])
    end
  end

  def test_with_tls_1_3_server
    # The connection to the TLS 1.3 server should pass.
    assert(connect_with_openssl_s_client(CONFIG_ITEMS[:tls_1_3][:host],
                                         CONFIG_ITEMS[:tls_1_3][:port]))
  end

  def connect_with_openssl_s_client(host, port)
    uri = URI("https://#{host}")
    puts "host: #{host}"
    puts "host: #{port}"
    Net::HTTP.start(host,
                    port,
                    use_ssl: true,
                    ca_file: CA_FILE) do |http|
      http.get(uri)
    end
  end
end
