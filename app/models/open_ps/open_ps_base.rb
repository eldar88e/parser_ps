class OpenPs::OpenPsBase < ApplicationRecord
  establish_connection(adapter: 'mysql2',
                       host: 'eldarap0.beget.tech',
                       database: 'eldarap0_openps',
                       username: 'eldarap0_openps',
                       password: 'a0b*WhCX')          # ENV.fetch('PASSWORD')

  self.inheritance_column = :_type_disabled
end
