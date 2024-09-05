# Projects::Project001::ImportJob.perform_now(run_id: 12, country: :ukraine, offset: 400, limit: 11)

class Projects::Project001::ImportJob < ApplicationJob
  queue_as :default

  USER_ID         = 2 # user for parsing
  GROUP_PRICE     = 1
  GROUP_OLD_PRICE = 2
  CURRENCY        = 'RUB'
  IBLOCK_ID       = 11  # catalog id
  PROCESSED_PROPERTY_IDS = [72, 73, 74, 76, 104, 229, 230, 231, 501, 502]

  def perform(**args)
    run_id      = args[:run_id]
    limit       = args[:limit]
    offset      = args[:offset]
    country     = args[:country]
    section_id  = { turkish: 57, ukraine: 184 }[country]                     # TODO Добавить индию
    module_name = { turkish: OpenPs, ukraine: PsUkraine }[country]           # TODO Добавить индию
    all_games   = module_name::Content.content_with_products(limit, offset)
    saved = updated = restored = 0
    all_games.each do |game|
      price         = PriceCountryService.call(price: game['product']['price_tl'].to_i, country: country)
      old_price     = generate_old_price(game, country)
      prices        = generate_price_data(price, old_price)
      other_params  = generate_other_params(game, price, old_price)
      str_for_hash  = generate_md5_hash(other_params, game['alias'])
      md5_hash      = Digest::MD5.hexdigest(str_for_hash)
      existing_item = Project001::Addition.find_by(data_source_url: game['product']['data_source_url'])

      if existing_item
        element = existing_item.b_iblock_element
        msg     = "There is no entry for the element in the database. sony_id: #{existing_item[:sony_id]}"
        Rails.log.error(msg) && TelegramService.call(msg) && next unless element # TODO создать новую запись element

        element.update!(ACTIVE: 'Y') && restored += 1 if element[:ACTIVE] != 'Y'
        existing_item.update(touched_run_id: run_id)
        #next if md5_hash == existing_item[:md5_hash] # TODO нужно закоментировать что бы обновились платформы и жанры

        existing_properties = element.b_iblock_element_properties
        selected_properties, remaining_properties = other_params.partition do |property|
          [74, 230].include?(property[:IBLOCK_PROPERTY_ID])
        end

        remaining_properties_ids = update_properties(remaining_properties, existing_properties)
        selected_properties_ids  = update_properties(selected_properties, existing_properties, true)

        properties_to_delete = existing_properties.where.not(id: selected_properties_ids + remaining_properties_ids)
                                                  .where(IBLOCK_PROPERTY_ID: PROCESSED_PROPERTY_IDS)
        properties_to_delete.destroy_all

        existing_prices = element.b_catalog_prices
        prices.each do |price|
          existing_prices.find_or_initialize_by(CATALOG_GROUP_ID: price[:CATALOG_GROUP_ID]).update!(price)
        end
        if prices.size < existing_prices.size
          existing_prices.where.not(CATALOG_GROUP_ID: prices.first[:CATALOG_GROUP_ID]).delete_all
          next
        end

        existing_item.update(md5_hash: md5_hash) && updated += 1
      else
        data             = generate_main_data(game, section_id, country)
        existing_element = Project001::BIblockElement.find_by(XML_ID: data[:XML_ID])
        if existing_element
          msg = "XML_ID #{data[:XML_ID]} is exist in the database!"
          Rails.logger.error(msg)
          TelegramService.call(msg)
          next
        end
        data[:prices]       = prices
        data[:addition]     = generate_addition_data(game, md5_hash, run_id, country)
        data[:other_params] = other_params
        data[:category]     = "games_#{country.to_s}/"
        Project001::BIblockElement.save_product(data)
        saved += 1
      end
    end

    [saved, updated, restored]
  end

  private

  def generate_md5_hash(params, url_alias)
    params.sort_by { |i| i[:IBLOCK_PROPERTY_ID] }.map { |i| i[:VALUE] }.join + url_alias
  end

  def update_properties(properties, existing_properties, selected=nil)
    properties.map do |item|
      data              = { IBLOCK_PROPERTY_ID: item[:IBLOCK_PROPERTY_ID] }
      data[:VALUE]      = item[:VALUE] if selected
      existing_property = existing_properties.find_or_initialize_by(data)
      existing_property.update!(item)
      existing_property.id
    end
  end

  def generate_old_price(game, country)
    return unless game['product']['old_price_tl'].present?

    PriceCountryService.call(price: game['product']['old_price_tl'].to_i, country: country)
  end

  def generate_other_params(game, price, old_price)
    old_price ||= price
    publisher = game['product']['publisher'].present? ? game['product']['publisher'] : 'Неизвестный'
    result = [
      { IBLOCK_PROPERTY_ID: 229, VALUE: game['product']['platform'].gsub(/, PS Vita|, PS3/, ''), VALUE_NUM: 0 },
      { IBLOCK_PROPERTY_ID: 231, VALUE: gen_lang_info(game['product']), VALUE_NUM: 0 },
      { IBLOCK_PROPERTY_ID: 104, VALUE: game['product']['type_game'] || 'Игра', VALUE_NUM: 0 },
      { IBLOCK_PROPERTY_ID: 72, VALUE: price, VALUE_ENUM: price, VALUE_NUM: price },
      { IBLOCK_PROPERTY_ID: 73, VALUE: old_price, VALUE_ENUM: old_price, VALUE_NUM: old_price },
      { IBLOCK_PROPERTY_ID: 501, VALUE: publisher, VALUE_NUM: 0 },
      { IBLOCK_PROPERTY_ID: 76, VALUE: 19, VALUE_ENUM: 19 }
    ]

    genres = game['product']['genre'].present? ? game['product']['genre'] : 'Другое'
    genres.split(', ').uniq.each do |genre|
      result << { IBLOCK_PROPERTY_ID: 230, VALUE: genre.strip, VALUE_NUM: 0 }
    end

    result << { IBLOCK_PROPERTY_ID: 74, VALUE: 15, VALUE_ENUM: 15 } if game['menuindex'] < 201
    result << { IBLOCK_PROPERTY_ID: 74, VALUE: 16, VALUE_ENUM: 16 } if game['menuindex'] < 21
    result << { IBLOCK_PROPERTY_ID: 74, VALUE: 18, VALUE_ENUM: 18 } if game['product']['old_price_tl'].present?

    release_date = game['product']['release']
    if release_date.present?
      new_end_date = release_date.to_date + 6.months
      result << { IBLOCK_PROPERTY_ID: 74, VALUE: 17, VALUE_ENUM: 17 } if Date.today < new_end_date
      result << { IBLOCK_PROPERTY_ID: 502, VALUE: release_date, VALUE_NUM: release_date }
    end

    result
  end

  def gen_lang_info(value)
    if value['rus_voice']
      'Русская озвучка'
    elsif value['rus_screen']
      'Русский язык интерфейса'
    else
      'Без русской локализации'
    end
  end

  def generate_main_data(data, section_id, country)
    time   = Time.current
    text   = data['content'] || ''
    search = data['pagetitle'].upcase
    search += "\n#{text.upcase}" if text.present?

    { TIMESTAMP_X: time, MODIFIED_BY: USER_ID, DATE_CREATE: time, CREATED_BY: USER_ID, IBLOCK_ID: IBLOCK_ID,
      IBLOCK_SECTION_ID: section_id, ACTIVE_FROM: Time.current, ACTIVE_TO: USER_ID, SORT: 500, NAME: data['pagetitle'],
      DETAIL_TEXT: text, DETAIL_TEXT_TYPE: 'html', SEARCHABLE_CONTENT: search, WF_STATUS_ID: 1, IN_SECTIONS: 'Y',
      XML_ID: "#{country}_#{data['product']['janr']}", CODE: data['alias'], TAGS: '', PREVIEW_TEXT: text[0..255],
      PREVIEW_TEXT_TYPE: 'html', TMP_ID: 0
    }
  end

  def generate_price_data(price, old_price)
    result = [
      { CATALOG_GROUP_ID: GROUP_PRICE,
      PRICE: price,
      CURRENCY: CURRENCY,
      TIMESTAMP_X: Time.current,
      PRICE_SCALE: price }
    ]
    result << { CATALOG_GROUP_ID: GROUP_OLD_PRICE, PRICE: old_price, CURRENCY: CURRENCY, TIMESTAMP_X: Time.current,
                PRICE_SCALE: old_price } if old_price.present?

    result
  end

  def generate_addition_data(data, md5_hash, run_id, country)
    { sony_id: data['product']['janr'], data_source_url: data['product']['data_source_url'], country: country,
      md5_hash: md5_hash, run_id: run_id, touched_run_id: run_id } # old version data['product']['md5_hash']
  end
end
