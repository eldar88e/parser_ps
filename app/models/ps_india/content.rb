class PsIndia::Content < PsIndia::PsIndiaBase
  self.table_name = 'modx_site_content'

  has_one :product, foreign_key: 'id'   #optional: true

  scope :active_contents, -> (parent) { where(deleted: 0, published: 1, parent: parent) }

  PARENT_PS5 = 25
  PARENT_PS4 = 24

  def self.content_with_products(limit, offset)
    order(:menuindex).active_contents([PARENT_PS5, PARENT_PS4])
                     .includes(:product).offset(offset).limit(limit).as_json(include: :product)
  end
end