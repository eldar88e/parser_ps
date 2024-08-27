class Projects::Project001::ImageDownloadJob < ApplicationJob
  queue_as :default
  BIG_IMAGE_SIZE    = 720
  MEDIUM_IMAGE_SIZE = 430
  MODULE_ID         = 'iblock'
  def perform(**args)
    run_id            = args[:run_id] || Project001::Run.last_id # TODO Добавить Run для каждой страны
    country           = args[:country]
    games_without_img = Project001::Addition.without_img(run_id, country)
    games_without_img.each do |game|
      next if game[:sony_id] == 'EP1018-PPSA07571_00-MKONEPREMIUM0000'

      detail_file  = download_image(game[:sony_id])
      next if detail_file.nil?

      preview_file = ImageService.call(image: detail_file, width: MEDIUM_IMAGE_SIZE, height: MEDIUM_IMAGE_SIZE)
      result       = FtpService.call(file: detail_file, folder: 'game_detail',
                                     sony_id: game[:sony_id], size: BIG_IMAGE_SIZE)
      result2      = FtpService.call(file: preview_file, folder: 'game_preview',
                                     sony_id: game[:sony_id], size: MEDIUM_IMAGE_SIZE)
      if result == 'error' || result2 == 'error'
        Rails.logger.error("Image download failed. Sony id: #{game[:sony_id]}")
        next
      end

      row_data = make_row_data(game, preview_file, detail_file)
      row_data.each { |data| save_img_info_to_tables(data, game) }
    end

    nil
  end

  private

  def save_img_info_to_tables(data, game)
    file_data = make_file_data(**data[0])
    Project001::BFile.save_file(data, game, file_data)
  end

  def make_row_data(game, preview_file, detail_file)
    [[{ width: MEDIUM_IMAGE_SIZE, height: MEDIUM_IMAGE_SIZE, file: preview_file, module_id: MODULE_ID,
        subdir: "#{MODULE_ID}/game_preview", sony_id: game[:sony_id] }, :PREVIEW_PICTURE],
     [{ width: BIG_IMAGE_SIZE, height: BIG_IMAGE_SIZE, file: detail_file, module_id: MODULE_ID,
        subdir: "#{MODULE_ID}/game_detail", sony_id: game[:sony_id] }, :DETAIL_PICTURE]]
  end

  def make_file_data(**args)
    original_name = "#{args[:sony_id]}_#{args[:width]}.jpg"
    { TIMESTAMP_X: Time.current,
      MODULE_ID: args[:module_id],
      HEIGHT: args[:height],
      WIDTH: args[:width],
      FILE_SIZE: args[:file].size,
      CONTENT_TYPE: "image/jpeg",
      SUBDIR: args[:subdir],
      FILE_NAME: "#{Digest::MD5.hexdigest(original_name)}.jpg",
      ORIGINAL_NAME: original_name,
      DESCRIPTION: '',
      HANDLER_ID: nil,
      EXTERNAL_ID: Digest::MD5.hexdigest(args[:file])
    }
  end

  def download_image(id)
    url      = "https://store.playstation.com/store/api/chihiro/00_09_000/container/TR/tr/99/#{id}/0/image?w=720&h=720"
    scraper  = Scraper::ScraperBaseService.new
    response = scraper.connect_to(url)
    return if response.status == 404

    response&.body
  rescue => e
    Rails.logger.error e.message
    nil
  end
end
