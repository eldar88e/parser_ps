class Project001::BSearchContentText < Project001::StoreBase
  self.table_name  = 'b_search_content_text'
  self.primary_key = 'SEARCH_CONTENT_ID'

  validates :SEARCH_CONTENT_MD5, presence: true
  validates :SEARCHABLE_CONTENT, presence: true

  belongs_to :b_search_content, class_name: 'Project001::BSearchContent', foreign_key: :SEARCH_CONTENT_ID, primary_key: :ID
end