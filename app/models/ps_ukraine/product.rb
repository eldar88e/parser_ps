class PsUkraine::Product < PsUkraine::PsUkraineBase
  self.table_name = 'modx_ms2_products'

  belongs_to :content, foreign_key: 'id'
end
