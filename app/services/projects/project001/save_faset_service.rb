class Projects::Project001::SaveFasetService < Parser::ParserBaseService
  def initialize(element)
    @element    = element
    @properties = element.b_iblock_element_properties.group_by(&:IBLOCK_PROPERTY_ID)
  end

  def self.call(element)
    new(element).save
  end

  def save
    existing_facets = @element.send("b_iblock_#{@element[:IBLOCK_ID]}_indexes".to_sym)
    if existing_facets.present?
      exist_price = existing_facets.find_by(FACET_ID: 3)&.VALUE_NUM.to_i
      new_price   = @properties[72]&.first&.VALUE.to_i
      return if exist_price == new_price

      update_all_facets(existing_facets)
    else
      save_new_facets(existing_facets)
    end
  end

  private

  def save_new_facets(existing_facets)
    facets = make_facets
    update_facets(facets, existing_facets, true) # true т.к. создание новых записей

    nil
  end

  def update_all_facets(existing_facets)
    facets = make_facets
    selected_facets, remaining_facets = facets.partition { |facet| [148, 460].include?(facet[:FACET_ID]) }
    remaining_facets_ids = update_facets(remaining_facets, existing_facets)
    selected_facets_ids  = update_facets(selected_facets, existing_facets, true)

    properties_to_delete = existing_facets.select do |i|
      finded = nil
      (selected_facets_ids + remaining_facets_ids).each do |ids|
        finded = true if i[:SECTION_ID] == ids[0] && i[:FACET_ID] == ids[1] && i[:VALUE] == ids[2] && i[:VALUE_NUM] == ids[3]
      end
      finded.nil?
    end

    properties_to_delete.each { |property| property.destroy }
  end

  def update_facets(facets, existing_facets, selected=nil)
    ids = []
    @section_ids ||= fetch_section_ids
    @section_ids.each do |section_id|
      i_s = @element[:IBLOCK_SECTION_ID] != section_id ? 0 : 1
      facets.each do |facet|
        facet[:VALUE_NUM] ||= 0
        facet[:INCLUDE_SUBSECTIONS] = i_s
        search_init_data            = { FACET_ID: facet[:FACET_ID], SECTION_ID: section_id }
        search_init_data[:VALUE]    = facet[:VALUE] if selected
        existing_facet              = existing_facets.find_or_initialize_by(search_init_data)
        existing_facet.update(facet)
        ids << existing_facet.id
      rescue => e
        Rails.logger.error(e.message)
        next
      end
    end

    ids
  end

  def fetch_section_ids
    id = @element[:IBLOCK_SECTION_ID]
    section_ids = [0, id]

    while id.present?
      id = Project001::BIblockSection.where(ID: id).pluck(:IBLOCK_SECTION_ID).first
      section_ids << id if id.present? # если нет вложений у секций то по умолчанию должно быть 1
    end

    section_ids
  end

  def make_facets
    price        = @properties[72]&.first&.VALUE
    old_price    = @properties[73]&.first&.VALUE
    old_price    = nil if price == old_price
    platform_id  = form_id(229)
    lang_id      = form_id(231)
    publisher_id = form_id(501)
    result       = [{ FACET_ID: 1, VALUE: 0 }, { FACET_ID: 3, VALUE: 6, VALUE_NUM: price }, # TODO возможно у FACET_ID: 3 value придется динамически получать с какойто таблицы
                    { FACET_ID: 458, VALUE: platform_id }, { FACET_ID: 462, VALUE: lang_id },
                    { FACET_ID: 1002, VALUE: publisher_id }]

    result << { FACET_ID: 5, VALUE: 6, VALUE_NUM: old_price } if old_price # TODO возможно у FACET_ID: 3 value придется динамически получать с какойто таблицы

    genres = @properties[230]&.map(&:VALUE) || []
    genres.each do |genre|
      genre_id = load_index_val(genre)
      result << { FACET_ID: 460, VALUE: genre_id, VALUE_NUM: 0 }
    end

    game_type    = @properties[104]&.first&.VALUE || 'Игра'
    game_type_id = load_index_val(game_type)
    result << { FACET_ID: 208, VALUE: game_type_id, VALUE_NUM: 0 }

    offers_ids = [15, 16, 17, 18]
    offers_ids.each { |id| result << { FACET_ID: 148, VALUE: id } if @properties[74]&.any? { |i| i.VALUE.to_i == id } }

    result
  end

  def form_id(id)
    item  = @properties[id]&.first
    value = item[:VALUE] if item
    value = 'Неизвестный' if id == 501 && item.nil?
    load_index_val(value)
  end

  def load_index_val(value)
    class_name = "Project001::BIblock#{@element[:IBLOCK_ID]}IndexVal"
    klass      = Object.const_get(class_name)
    klass.find_or_create_by(VALUE: value)[:ID]
  end
end
