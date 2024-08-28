class OpenPs::OpenPsBase < ApplicationRecord
  establish_connection(adapter: 'mysql2',
                       host: ENV.fetch('OPEN_PS_HOST'),
                       database: ENV.fetch('OPEN_PS_BD'),
                       username: ENV.fetch('OPEN_PS_USER'),
                       password: ENV.fetch('OPEN_PS_PASSWORD'))

  self.inheritance_column = :_type_disabled
end
