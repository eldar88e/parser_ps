class Project001::BSearchContent < Project001::StoreBase
  self.table_name  = 'b_search_content'
  self.primary_key = 'ID'

  validates :URL, presence: true
  validates :TITLE, presence: true

  belongs_to :b_iblock_element, class_name: 'Project001::BIblockElement', foreign_key: :ITEM_ID, primary_key: :ID
  has_one :b_search_content_text, class_name: 'Project001::BSearchContentText', foreign_key: :SEARCH_CONTENT_ID, primary_key: :ID
  has_many :b_search_content_titles, class_name: 'Project001::BSearchContentTitle', foreign_key: :SEARCH_CONTENT_ID, primary_key: :ID
  has_one :b_search_content_site, class_name: 'Project001::BSearchContentSite', foreign_key: :SEARCH_CONTENT_ID, primary_key: :ID
  has_many :b_search_content_rights, class_name: 'Project001::BSearchContentRight', foreign_key: :SEARCH_CONTENT_ID, primary_key: :ID
end