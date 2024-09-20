class Project001::BIblockSectionElement < Project001::StoreBase
  self.table_name = 'b_iblock_section_element'
  self.primary_key = [:IBLOCK_SECTION_ID, :IBLOCK_ELEMENT_ID, :ADDITIONAL_PROPERTY_ID]

  validates :IBLOCK_SECTION_ID, presence: true

  belongs_to :b_iblock_element, class_name: 'Project001::BIblockElement', foreign_key: :IBLOCK_ELEMENT_ID, primary_key: :ID
end

