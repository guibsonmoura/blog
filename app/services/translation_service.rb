require "net/http"
require "json"

class TranslationService
  URL = ENV.fetch("TRANSLATION_SERVICE_URL", "http://localhost:8000")

  class UnavailableError < StandardError; end

  def self.translate(text)
    uri = URI("#{URL}/translate")
    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json")
    request.body = { text: text }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 5, read_timeout: 60) do |http|
      http.request(request)
    end

    raise UnavailableError, "Translation service returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch("translation")
  rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    raise UnavailableError, "Translation service unreachable: #{e.message}"
  end
end
