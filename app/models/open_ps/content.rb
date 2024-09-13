class OpenPs::Content < OpenPs::OpenPsBase
  self.table_name = 'modx_site_content'

  has_one :product, foreign_key: 'id'   #optional: true

  scope :active_contents, -> (parent) { where(deleted: 0, published: 1, parent: parent) }

  PARENT_PS5 = 218
  PARENT_PS4 = 217

  def self.content_with_products(limit, offset)
    order(:menuindex).active_contents([PARENT_PS5, PARENT_PS4])
                     .includes(:product).offset(offset).limit(limit).as_json(include: :product)
  end
end