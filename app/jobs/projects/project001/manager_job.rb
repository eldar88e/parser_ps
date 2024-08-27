class Projects::Project001::ManagerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    scraper
  end


  def scraper
    scraper = Projects::Project001::ScraperService.new
    scraper.scrape
  end
end
