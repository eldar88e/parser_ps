class Project001::BIblockElement < Project001::StoreBase
  TYPE                  = 1
  QUANTITY              = 9000
  MEASURE               = 5
  AVAILABLE             = 'Y'
  BUNDLE                = 'N'
  SUBSCRIBE             = 'D'
  CAN_BUY_ZERO          = 'D'
  NEGATIVE_AMOUNT_TRACE = 'D'
  SELECT_BEST_PRICE     = 'N'
  BLOG_ID               = 1
  URL                   = 'http://45store.ru/catalog/'
  ENABLE_TRACKBACK      = 'N'

  validates :NAME, presence: true
  validates :CODE, presence: true
  validates :XML_ID, presence: true, uniqueness: true

  self.table_name  = 'b_iblock_element'
  self.primary_key = 'ID'

  has_one :addition, class_name: 'Project001::Addition', primary_key: :ID
  has_many :b_catalog_prices, class_name: 'Project001::BCatalogPrice', foreign_key: :PRODUCT_ID, primary_key: :ID
  has_one :b_iblock_section_element, class_name: 'Project001::BIblockSectionElement', foreign_key: :IBLOCK_ELEMENT_ID, primary_key: :ID
  has_many :b_iblock_element_properties, class_name: 'Project001::BIblockElementProperty', foreign_key: :IBLOCK_ELEMENT_ID, primary_key: :ID
  has_one :b_catalog_product, class_name: 'Project001::BCatalogProduct', foreign_key: :ID, primary_key: :ID
  belongs_to :b_file, class_name: 'Project001::BFile', foreign_key: :DETAIL_PICTURE, primary_key: :ID, optional: true
  has_many :b_iblock_element_iprops, class_name: 'Project001::BIblockElementIprop', foreign_key: :ELEMENT_ID, primary_key: :ID
  has_one :b_catalog_measure_ratio, class_name: 'Project001::BCatalogMeasureRatio', foreign_key: :PRODUCT_ID, primary_key: :ID
  has_many :b_iblock_11_indexes, class_name: 'Project001::BIblock11Index', foreign_key: :ELEMENT_ID, primary_key: :ID
  has_one :b_search_content, class_name: 'Project001::BSearchContent', foreign_key: :ITEM_ID, primary_key: :ID

  scope :not_touched, ->(run_id, country) do
    joins(:addition).where(addition: { country: country.to_sym }).where.not(addition: { touched_run_id: run_id })
  end

  def self.save_product(data)
    prices       = data.delete(:prices)
    addition     = data.delete(:addition)
    other_params = data.delete(:other_params)
    category     = data.delete(:category)
    self.transaction do
      element = create(data)
      element.create_addition(addition)
      prices.each { |price| element.b_catalog_prices.build(price).save! }
      element.build_b_iblock_section_element(IBLOCK_SECTION_ID: data[:IBLOCK_SECTION_ID]).save!
      other_params.each { |params| element.b_iblock_element_properties.build(params).save! }
      element.build_b_catalog_product(form_product_data).save!

      b_blog_post = Project001::BBlogPost.create!(
        TITLE: data[:NAME], BLOG_ID: BLOG_ID, AUTHOR_ID: data[:CREATED_BY], ENABLE_TRACKBACK: ENABLE_TRACKBACK,
        DETAIL_TEXT: "[URL=#{URL}#{category}#{data[:CODE]}/]#{data[:NAME]}[/URL]", DATE_CREATE: data[:DATE_CREATE],
        DATE_PUBLISH: data[:DATE_CREATE]
      )

      element.b_iblock_element_properties.build(
        { IBLOCK_PROPERTY_ID: 129, VALUE: b_blog_post[:ID], VALUE_NUM: b_blog_post[:ID] }
      ).save!

      element.build_b_catalog_measure_ratio(IS_DEFAULT: 'Y').save!

      nil
    end
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.error e.message
  end

  private

  def self.make_description(name, platform) # TODO удалить
    "Купите #{name} для PlayStation в 45store.ru. Эксклюзив для #{platform}. Акции и скидки на игры. Оформите заказ прямо сейчас!"
  end

  def self.make_keywords(name, platform, genre) # TODO удалить
    ["купить #{name}", "#{name} #{platform}", "#{name} на PlayStation", 'эксклюзив PlayStation',
     "игры для #{platform}", "#{genre} #{platform}", 'акции на игры', "скидки на #{name}", '45store'].join(', ')
  end

  def self.form_product_data
    { QUANTITY: QUANTITY, TYPE: TYPE, TIMESTAMP_X: Time.current, MEASURE: MEASURE, AVAILABLE: AVAILABLE,
      BUNDLE: BUNDLE, VAT_ID: nil, SUBSCRIBE: SUBSCRIBE, SELECT_BEST_PRICE: SELECT_BEST_PRICE,
      CAN_BUY_ZERO: CAN_BUY_ZERO, NEGATIVE_AMOUNT_TRACE: NEGATIVE_AMOUNT_TRACE }
  end
end
