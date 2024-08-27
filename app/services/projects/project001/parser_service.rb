class Projects::Project001::ParserService < Parser::ParserBaseService
  def initialize(**params)
    super
  end

  def parse

  end

  def get_last_page
    count_result   = @html.at('div.results').text.match(/\d+/).to_s.to_i
    games_per_page = @html.css('div.game-collection-item').size
    last_page_bad  = count_result / games_per_page
    last_page_f    = count_result / games_per_page.to_f
    last_page_f > last_page_bad ? last_page_bad + 1 : last_page_bad
  end
end
