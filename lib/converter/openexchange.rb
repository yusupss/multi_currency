require 'logger'

module MultiCurrency
  module Converter
    module Openexchange
      def self.get_rate_and_cache(source_currency, to_currency, date)
        app_id = ENV['OPEN_EXCHANGE_RATES_APP_ID'] || '6ecb58dda5bb46a2b4fc6bcfbffc8c91'
        if (source_currency.try(:downcase) == to_currency.try(:downcase)) || (source_currency.nil? || to_currency.nil?)
          rate = 1.0
        else
          exchange_rate = ExchangeRate.find_by_from_code_and_to_code_and_date(source_currency.downcase, to_currency.downcase, date)
          rate = if exchange_rate.present?
            exchange_rate.rate
          else
            response = Net::HTTP.get_response(URI("https://openexchangerates.org/api/historical/#{(date - 1).strftime("%Y-%m-%d")}.json?app_id=#{app_id}&base=#{source_currency.upcase}&symbols=#{to_currency.upcase}"))
            if response.is_a? Net::HTTPOK
              log = Logger.new(STDOUT)
              log.info "=========== API Calling =========== from #{source_currency} to #{to_currency} === calling at #{date} ============"
              data = JSON.parse(response.body)
              rate_to = data["rates"]["#{to_currency.upcase}"]
              ExchangeRate.create!(from_code: source_currency, to_code: to_currency, date: date, rate: rate_to.to_f)
              rate_to.to_f
            else
              raise "#{response.code}: #{response.body}"
            end
          end
        end
        rate
      end

    end
  end
end
