class Projects::Project001::ImportJob < ApplicationJob
  queue_as :default

  USER_ID         = 2
  GROUP_PRICE     = 1
  GROUP_OLD_PRICE = 2
  CURRENCY        = 'RUB'
  IBLOCK_ID       = 11  # turkish game id
  PROCESSED_PROPERTY_IDS = [72, 73, 74, 76, 104, 229, 230, 231, 501, 502]

  def perform(**args)
    run_id    = args[:run_id]
    limit     = args[:limit]
    offset    = args[:offset]
    country   = args[:country]
    all_games = OpenPs::Content.content_with_products(limit, offset)
    all_games.each do |game|
      price         = PriceCountryService.call(price: game['product']['price_tl'].to_i, country: country)
      old_price     = generate_old_price(game, country)
      prices        = generate_price_data(price, old_price)
      other_params  = generate_other_params(game, price, old_price)
      existing_item = Project001::Addition.find_by(sony_id: game['product']['janr']) # janr is sony_id

      if existing_item
        existing_item.update!(touched_run_id: run_id) && next if game['product']['md5_hash'] == existing_item[:md5_hash]

        element = existing_item.b_iblock_element
        Rails.log.error('There is no entry for the element in the database') && next unless element

        #
        #data = generate_main_data(game)
        #element.update!(data)
        #
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

        existing_item.update!(md5_hash: game['product']['md5_hash'], touched_run_id: run_id)
      else
        data                = generate_main_data(game)
        data[:prices]       = prices
        data[:addition]     = generate_addition_data(game, run_id, country)
        data[:other_params] = other_params
        Project001::BIblockElement.save_product(data)
      end
    end

    nil
  end

  private

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
      { IBLOCK_PROPERTY_ID: 229, VALUE: game['product']['platform'], VALUE_NUM: 0 },
      { IBLOCK_PROPERTY_ID: 231, VALUE: gen_lang_info(game['product']), VALUE_NUM: 0 },
      { IBLOCK_PROPERTY_ID: 104, VALUE: game['product']['type_game'] || 'Игра', VALUE_NUM: 0 },
      { IBLOCK_PROPERTY_ID: 72, VALUE: price, VALUE_ENUM: price, VALUE_NUM: price },
      { IBLOCK_PROPERTY_ID: 73, VALUE: old_price, VALUE_ENUM: old_price, VALUE_NUM: old_price },
      { IBLOCK_PROPERTY_ID: 501, VALUE: publisher, VALUE_NUM: 0 },
      { IBLOCK_PROPERTY_ID: 76, VALUE: 19, VALUE_ENUM: 19 }
    ]

    genres = game['product']['genre'].present? ? game['product']['genre'] : 'Неизвестный'
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

  def generate_main_data(data)
    time   = Time.current
    text   = data['content'] || ''
    search = data['pagetitle'].upcase
    search += "\n#{text.upcase}" if text.present?

    { TIMESTAMP_X: time, MODIFIED_BY: USER_ID, DATE_CREATE: time, CREATED_BY: USER_ID, IBLOCK_ID: IBLOCK_ID,
      IBLOCK_SECTION_ID: 57, ACTIVE_FROM: Time.current, ACTIVE_TO: USER_ID, SORT: 500, NAME: data['pagetitle'],
      DETAIL_TEXT: text, DETAIL_TEXT_TYPE: 'html', SEARCHABLE_CONTENT: search, WF_STATUS_ID: 1, IN_SECTIONS: 'Y',
      XML_ID: data['product']['janr'], CODE: data['alias'], TAGS: '', PREVIEW_TEXT: text[0..255],
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

  def generate_addition_data(data, run_id, country)
    { sony_id: data['product']['janr'], data_source_url: data['product']['data_source_url'], country: country,
      md5_hash: data['product']['md5_hash'], run_id: run_id, touched_run_id: run_id } # TODO сделать свой md5_hash
  end
end
