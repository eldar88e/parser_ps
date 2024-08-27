class Project001::BFile < Project001::StoreBase
  #validates :PRICE, presence: true, numericality: true

  self.table_name = 'b_file'
  self.primary_key = 'ID'

  has_many :b_iblock_elements, class_name: 'Project001::BIblockElement', foreign_key: :DETAIL_PICTURE, primary_key: :ID

  def self.save_file(data, game, file_data)
    self.transaction do
      b_file = self.create!(file_data)
      game.b_iblock_element.update!(data[1] => b_file.ID)
    end
  end
end
