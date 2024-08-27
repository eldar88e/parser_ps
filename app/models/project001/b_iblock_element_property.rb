class Project001::BIblockElementProperty < Project001::StoreBase
  self.table_name = 'b_iblock_element_property'
  self.primary_key = 'ID'

  validates :IBLOCK_PROPERTY_ID, presence: true

  belongs_to :b_iblock_element, class_name: 'Project001::BIblockElement', foreign_key: :IBLOCK_ELEMENT_ID, primary_key: :ID
end
