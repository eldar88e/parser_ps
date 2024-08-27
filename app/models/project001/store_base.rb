class Project001::StoreBase < ApplicationRecord
  establish_connection(adapter: 'mysql2',
                       host: ENV['STORE_45_HOST'],
                       database: ENV['STORE_45_BD'],
                       username: ENV['STORE_45_USER'],
                       password: ENV.fetch('STORE_45_PASSWORD')
  )
end
