class Project001::BIblockElementIprop < Project001::StoreBase
  self.table_name  = 'b_iblock_element_iprop'
  self.primary_key = [:ELEMENT_ID, :IPROP_ID]

  validates :VALUE, presence: true
  validates :IPROP_ID, presence: true
  validates :IBLOCK_ID, presence: true
  validates :SECTION_ID, presence: true

  belongs_to :b_iblock_element, class_name: 'Project001::BIblockElement', foreign_key: :ELEMENT_ID, primary_key: :ID
end