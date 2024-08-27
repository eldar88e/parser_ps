class Project001::BIblock11Index < Project001::StoreBase
  self.table_name  = 'b_iblock_11_index'
  self.primary_key = [:SECTION_ID, :FACET_ID, :VALUE, :VALUE_NUM, :ELEMENT_ID]

  belongs_to :b_iblock_element, class_name: 'Project001::BIblockElement', foreign_key: :ELEMENT_ID, primary_key: :ID
end