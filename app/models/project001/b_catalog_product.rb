class Project001::BCatalogProduct < Project001::StoreBase
  self.table_name = 'b_catalog_product'
  self.primary_key = 'ID'

  validates :QUANTITY, presence: true
  validates :TYPE, presence: true

  belongs_to :b_iblock_element, class_name: 'Project001::BIblockElement', foreign_key: :ID, primary_key: :ID
end
