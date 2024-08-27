class Project001::BSearchContentSite < Project001::StoreBase
  self.table_name  = 'b_search_content_site'
  self.primary_key = 'SEARCH_CONTENT_ID'

  belongs_to :b_search_content, class_name: 'Project001::BSearchContent', foreign_key: :SEARCH_CONTENT_ID, primary_key: :ID
end