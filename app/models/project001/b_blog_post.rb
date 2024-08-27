class Project001::BBlogPost < Project001::StoreBase
  self.table_name  = 'b_blog_post'
  self.primary_key = 'ID'

  validates :TITLE, presence: true
  validates :DETAIL_TEXT, presence: true
  validates :AUTHOR_ID, presence: true
end

