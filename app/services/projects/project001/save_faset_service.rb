class Projects::Project001::SaveFasetService < Parser::ParserBaseService
  def initialize(element)
    @element    = element
    @properties = element.b_iblock_element_properties.group_by(&:IBLOCK_PROPERTY_ID)
  end

  def self.call(element)
    new(element).save
  end

  def save
    facets          = make_facets
    existing_facets = @element.send("b_iblock_#{@element[:IBLOCK_ID]}_indexes".to_sym)
    return update_all_facets(facets, existing_facets) if existing_facets.present?

    save_new_facets(facets, existing_facets)
  end

  private

  def save_new_facets(facets, existing_facets)
    update_facets(facets, existing_facets)

    nil
  end

  def update_all_facets(facets, existing_facets)
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
    ids         = []
    section_ids = select_block_section(@element[:IBLOCK_SECTION_ID])
    binding.pry
    section_ids.each do |i|
      section_id = i.zero? ? 0 : @element[:IBLOCK_SECTION_ID]
      facets.each do |facet|
        facet[:VALUE_NUM] ||= 0
        data           = { FACET_ID: facet[:FACET_ID], INCLUDE_SUBSECTIONS: i }
        data[:VALUE]   = facet[:VALUE] if selected
        existing_facet = existing_facets.find_or_initialize_by(data)
        existing_facet.update!(facet.merge({ SECTION_ID: section_id }))
        ids << existing_facet.id
      end
    end

    ids
  end

  def select_block_section(id)
    section_ids = [0] # по умолчанию секции начинаются с 0

    while id.present?
      id = Project001::BIblockSection.where(ID: id).pluck(:IBLOCK_SECTION_ID).first
      section_ids << (id.present? ? id : 1) # если нет вложений у секций то по умолчанию должно быть 1
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
    result       = [{ FACET_ID: 1, VALUE: 0 }, { FACET_ID: 3, VALUE: 1, VALUE_NUM: price },
                    { FACET_ID: 458, VALUE: platform_id }, { FACET_ID: 462, VALUE: lang_id },
                    { FACET_ID: 1002, VALUE: publisher_id }]

    result << { FACET_ID: 5, VALUE: 1, VALUE_NUM: old_price } if old_price

    genres = @properties[230]&.map(&:VALUE) || []
    genres.each do |genre|
      genre_id = load_index_val(genre)
      result << { FACET_ID: 460, VALUE: genre_id, VALUE_NUM: 0 }
    end

    game_type    = @properties[104]&.first&.VALUE || 'Игра'
    game_type_id = load_index_val(game_type)
    result << { FACET_ID: 208, VALUE: game_type_id, VALUE_NUM: 0 }

    offers_ids = [15, 16, 17, 18]
    offers_ids.each { |id| result << { FACET_ID: 148, VALUE: id } if @properties[74]&.any? { |i| i.VALUE == id } }

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
