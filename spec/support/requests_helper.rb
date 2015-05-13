module RequestsHelper
  def json
    @json ||= JSON.parse(response.body, symbolize_names: true)
  end

  def xml
    @xml ||= Nokogiri::XML(response.body)
  end
end
