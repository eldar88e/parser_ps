class Project001::BCatalogMeasureRatio < Project001::StoreBase
  self.table_name = 'b_catalog_measure_ratio'
  self.primary_key = 'ID'

  belongs_to :b_iblock_element, class_name: 'Project001::BIblockElement', foreign_key: :PRODUCT_ID, primary_key: :ID
end
