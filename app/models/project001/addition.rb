class Project001::Addition < Project001::StoreBase
  self.table_name = 'additions'

  validates :sony_id, presence: true, uniqueness: { scope: :country }
  validates :data_source_url, presence: true
  validates :md5_hash, presence: true, uniqueness: true

  belongs_to :b_iblock_element, class_name: 'Project001::BIblockElement', primary_key: :ID
  # belongs_to :run_turkish, class_name: 'Project001::RunTurkish', foreign_key: :run_id
  # belongs_to :run_ukraine, class_name: 'Project001::RunUkraine', foreign_key: :run_id

  enum country: [:turkish, :ukraine, :hindi]

  scope :without_img, ->(run_id, country) {
    includes(:b_iblock_element)
      .where(touched_run_id: run_id,
             country: country.to_sym,
             b_iblock_element: { DETAIL_PICTURE: nil })
  }

  scope :touched, ->(run_id, country) do
    where(touched_run_id: run_id, country: country.to_sym)
      .includes(b_iblock_element: [:b_iblock_element_properties, :b_iblock_11_indexes])
  end
end