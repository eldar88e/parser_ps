class Projects::Project001::SaveSearchDataService < Parser::ParserBaseService
  def initialize(element)
    @element = element
    @data    = make_main_search_data
  end

  def self.call(element)
    new(element).save
  end

  def save
    return if @element.b_search_content.present? # @element.b_search_content.update(@data) &&

    ActiveRecord::Base.transaction do
      @element.build_b_search_content(@data).save!
      search_item = @element.b_search_content
      search_item.build_b_search_content_text(
        SEARCHABLE_CONTENT: @element[:SEARCHABLE_CONTENT],
        SEARCH_CONTENT_MD5: Digest::MD5.hexdigest(@element[:SEARCHABLE_CONTENT])
      ).save!

      name = @element[:NAME].upcase
      name.split(' ').each do |word|
        search_item.b_search_content_titles.build(WORD: word, SITE_ID: 's1', POS: name.index(word)).save!
      rescue ActiveRecord::RecordNotUnique
        next
      end

      %w[G1 G2].each { |i| search_item.b_search_content_rights.build(GROUP_CODE: i).save! }

      search_item.build_b_search_content_site(SITE_ID: 's1', URL: '').save!
    end

    nil
  end

  private

  def make_main_search_data
    catalog = 'aspro_lite_catalog'
    {
      DATE_CHANGE: Time.current,
      MODULE_ID: 'iblock',
      URL: "=ID=#{@element[:ID]}&EXTERNAL_ID=#{@element[:XML_ID]}&IBLOCK_SECTION_ID=#{@element[:IBLOCK_SECTION_ID]}&IBLOCK_TYPE_ID=#{catalog}&IBLOCK_ID=#{@element[:IBLOCK_ID]}&IBLOCK_CODE=#{catalog}&IBLOCK_EXTERNAL_ID=#{catalog}_s1&CODE=#{@element[:CODE]}",
      TITLE: @element[:NAME],
      BODY: @element[:DETAIL_TEXT] || '',
      TAGS: '',
      PARAM1: catalog,
      PARAM2: @element[:IBLOCK_ID],
      DATE_FROM: Time.current
    }
  end
end
