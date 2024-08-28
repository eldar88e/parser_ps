class OpenPs::PsUkraineBase < ApplicationRecord
  establish_connection(adapter: 'mysql2',
                       host: ENV.fetch('PS_UKRAINE_HOST'),
                       database: ENV.fetch('PS_UKRAINE_BD'),
                       username: ENV.fetch('PS_UKRAINE_USER'),
                       password: ENV.fetch('PS_UKRAINE_PASSWORD'))

  self.inheritance_column = :_type_disabled
end
