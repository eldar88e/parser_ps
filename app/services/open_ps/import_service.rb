class OpenPs::ImportService
  PARENT_PS5 = 218
  PARENT_PS4 = 217
  NEED_KEYS  = %i[pagetitle alias content article price old_price image thumb price_tl old_price_tl site_link
                      janr data_source_url platform price_bonus price_bonus_tl type_game rus_voice rus_screen
                      genre release publisher discount_end_date].freeze

  def initialize(**args)
    @quantity = args[:quantity]
  end

  def self.call
    new.get_top_games
  end


end