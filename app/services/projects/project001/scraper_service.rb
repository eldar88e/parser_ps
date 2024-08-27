class Projects::Project001::ScraperService < Scraper::ScraperBaseService
  def initialize(**params)
    super(**params)
  end

  def scrape
    run_id     = 1
    params     = '?sort=most-watchlisted'
    first_page = 'https://psdeals.net/tr-store/all-games'
    last_page  = make_last_page(first_page + params)

    puts "Found #{last_page} pages with a list of games (36 games/page) on the website #{first_page}" if Rails.env.development?

    pages = (1..last_page).to_a

    pages.each_slice(6) do |page_group|
      threads = []

      page_group.each do |page|
        threads << Thread.new do
          link = "#{first_page}/#{page}#{params}"
          #puts "Processing page #{page}" if Rails.env.development?
          game_list = get_response(link).body
          peon.put(file: "game_list_#{page}.html", content: game_list, subfolder: "#{run_id}_games_tr")
          @count += 1
        end
      end

      threads.each(&:join)
      sleep(rand(0.3..1.9))
    end
  end

  private

  def make_last_page(first_page)
    game_list = get_response(first_page).body
    parser    = Projects::Project001::ParserService.new(html: game_list)
    parser.get_last_page
  end

  def get_response(link, try=1)
    #headers  = { 'Referer' => @referers.sample, 'Accept-Language' => 'tr-TR' }
    headers  = { 'Accept-Language': 'tr-TR' }
    response = connect_to(link, ssl_verify: false, headers: headers)
    raise 'Error receiving response from server' unless response.present?
    response
  rescue => e
    try += 1

    if try < 4
      Rails.logger.error "#{e.message} || #{e.class} || #{link} || try: #{try}"
      sleep 5 * try
      retry
    end
  end
end
