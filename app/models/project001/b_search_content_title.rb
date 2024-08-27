class Project001::BSearchContentTitle < Project001::StoreBase
  self.table_name  = 'b_search_content_title'
  self.primary_key = 'SEARCH_CONTENT_ID'

  validates :WORD, presence: true
  validates :POS, presence: true

  belongs_to :b_search_content, class_name: 'Project001::BSearchContent', foreign_key: :SEARCH_CONTENT_ID, primary_key: :ID
end
