class PriceCountryService
  def initialize(**args)
    @price   = args[:price]
    @country = args[:country]
  end

  def self.call(**args)
    new(**args).formit_price
  end

  def formit_price
    exchange_rate = send("make_exchange_rate_#{@country}".to_sym)
    round_up_price(@price * exchange_rate)
  end

  private

  def round_up_price(price)
    (price / 10.to_f).round * 10
  end

  def make_exchange_rate_turkish
    if @price < 300
      ENV.fetch("LOWEST_PRICE") { 5 }.to_f
    elsif @price >= 300 && @price < 800
      ENV.fetch("LOW_PRICE") { 4.5 }.to_f
    elsif @price >= 800 && @price < 1200
      ENV.fetch("MEDIAN_PRICE") { 4 }.to_f
    elsif @price >= 1200 && @price < 1700
      ENV.fetch("HIGH_PRICE") { 4 }.to_f
    else
      ENV.fetch("HIGHEST_PRICE") { 4 }.to_f
    end
  end

  def make_exchange_rate_ukraine
    if @price < 300
      ENV.fetch("LOWEST_PRICE") { 5 }.to_f
    elsif @price >= 300 && @price < 800
      ENV.fetch("LOW_PRICE") { 4.5 }.to_f
    elsif @price >= 800 && @price < 1200
      ENV.fetch("MEDIAN_PRICE") { 4 }.to_f
    elsif @price >= 1200 && @price < 1700
      ENV.fetch("HIGH_PRICE") { 4 }.to_f
    else
      ENV.fetch("HIGHEST_PRICE") { 4 }.to_f
    end
  end

  def make_exchange_rate_india
    @price < 8000 ? 1.5 : 1.4
  end
end
