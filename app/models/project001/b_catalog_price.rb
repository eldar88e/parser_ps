class Project001::BCatalogPrice < Project001::StoreBase
  self.table_name = 'b_catalog_price'
  self.primary_key = 'ID'

  validates :PRICE, presence: true, numericality: true

  belongs_to :b_iblock_element, class_name: 'Project001::BIblockElement', foreign_key: :PRODUCT_ID, primary_key: :ID
end
