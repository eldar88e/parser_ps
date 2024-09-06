class Projects::Project001::ImageDownloadJob < ApplicationJob
  queue_as :default

  BIG_IMAGE_SIZE    = 720
  MEDIUM_IMAGE_SIZE = 430
  MODULE_ID         = 'iblock'

  def perform(**args)
    run_id            = args[:run_id]
    country           = args[:country]
    uploaded_image    = 0
    set_exist_image   = 0
    upld_exist_img    = 0
    error_download    = 0
    games_without_img = form_list(run_id: run_id, country: country, all: args[:all])
    games_without_img.each do |game|
      detail_file_name  = "#{game[:sony_id]}_720.jpg"
      exist_detail_item = Project001::BFile.find_by(ORIGINAL_NAME: detail_file_name)
      if exist_detail_item.present?
        preview_file_name     = "#{game[:sony_id]}_430.jpg"
        existing_preview_file = Project001::BFile.find_by(ORIGINAL_NAME: preview_file_name)
        game.b_iblock_element.update(DETAIL_PICTURE: exist_detail_item[:ID])
        if existing_preview_file.present?
          game.b_iblock_element.update(DETAIL_PICTURE: existing_preview_file[:ID])
          set_exist_image += 1
          next
        else
          exist_detail_file_name = exist_detail_item[:FILE_NAME]
          new_preview_file       = download_self_image(exist_detail_file_name)
          new_preview_file       = ImageService.call(image: new_preview_file, width: MEDIUM_IMAGE_SIZE,
                                                     height: MEDIUM_IMAGE_SIZE)
          downloading            = FtpService.call(file: new_preview_file, folder: 'game_preview',
                                                   sony_id: game[:sony_id], size: MEDIUM_IMAGE_SIZE)
          if downloading == 'error'
            msg = "Existing image download or upload failed. Sony id: #{game[:sony_id]}"
            Rails.logger.error msg
            TelegramService.call msg
            next
          end

          row_data = make_row_data(game, preview_file)
          row_data.each { |data| save_img_info_to_tables(data, game) }
          upld_exist_img += 1
          next
        end
      end

      detail_file = download_image(game[:sony_id], game[:country].to_sym)
      if detail_file.nil?
        msg = "Image download failed. Sony id: #{game[:sony_id]}"
        Rails.logger.error msg
        TelegramService.call msg
        error_download += 1
        next
      end

      preview_file = ImageService.call(image: detail_file, width: MEDIUM_IMAGE_SIZE, height: MEDIUM_IMAGE_SIZE)
      result       = FtpService.call(file: detail_file, folder: 'game_detail',
                                     sony_id: game[:sony_id], size: BIG_IMAGE_SIZE)
      result2      = FtpService.call(file: preview_file, folder: 'game_preview',
                                     sony_id: game[:sony_id], size: MEDIUM_IMAGE_SIZE)
      if result == 'error' || result2 == 'error'
        msg = "Image upload failed. Sony id: #{game[:sony_id]}"
        Rails.logger.error msg
        TelegramService.call(msg)
        next
      end

      sleep rand(0.7..2.9)
      row_data = make_row_data(game, preview_file, detail_file)
      row_data.each { |data| save_img_info_to_tables(data, game) }
      uploaded_image += 1
    end
    msg = ''
    msg << "#{country.to_s.capitalize}\n" if country
    msg << "Загружено #{uploaded_image} картинок.\n" if uploaded_image > 0
    msg << "Загружено превью из существующей #{upld_exist_img} картинок.\n" if upld_exist_img > 0
    msg << "Указаны существующие #{set_exist_image} картинок.\n" if set_exist_image > 0
    msg << "Ошибка загрузки #{error_download} картинок.\n" if error_download > 0
    TelegramService.call(msg.strip)
  end

  private

  def form_list(**args) # run_id, country, all
    if args[:all]
      Project001::Addition.includes(:b_iblock_element).where(b_iblock_element: { DETAIL_PICTURE: nil })
    elsif args[:run_id] && args[:country]
      Project001::Addition.without_img(args[:run_id], args[:country])
    elsif args[:country]
      Project001::Addition.includes(:b_iblock_element)
                          .where(country: args[:country].to_sym, b_iblock_element: { DETAIL_PICTURE: nil })
    else
      []
    end
  end

  def save_img_info_to_tables(data, game)
    file_data = make_file_data(**data[0])
    Project001::BFile.save_file(data, game, file_data)
  end

  def make_row_data(game, preview_file, detail_file=nil)
    result = [[{ width: MEDIUM_IMAGE_SIZE, height: MEDIUM_IMAGE_SIZE, file: preview_file, module_id: MODULE_ID,
        subdir: "#{MODULE_ID}/game_preview", sony_id: game[:sony_id] }, :PREVIEW_PICTURE]]
    return result unless detail_file

    result << [{ width: BIG_IMAGE_SIZE, height: BIG_IMAGE_SIZE, file: detail_file, module_id: MODULE_ID,
                 subdir: "#{MODULE_ID}/game_detail", sony_id: game[:sony_id] }, :DETAIL_PICTURE]
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

  def download_image(id, country)
    path     = { turkish: 'TR/tr', ukraine: 'UA/ru', india: 'IN/en' }[country]
    url      = "https://store.playstation.com/store/api/chihiro/00_09_000/container/#{path}/99/#{id}/0/image?w=720&h=720"
    scraper  = Scraper::ScraperBaseService.new
    response = scraper.connect_to(url)
    return if !response.present? || response.status != 200

    response.body
  rescue => e
    Rails.logger.error e.message
    nil
  end

  def download_self_image(detail_file_name)
    scraper  = Scraper::ScraperBaseService.new
    url      = 'https://45store.ru/upload/iblock/game_detail/' + detail_file_name
    response = scraper.connect_to(url)
    return if !response.present? || response.status != 200

    response.body
  end
end
