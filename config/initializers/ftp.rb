Rails.application.configure do
  FTP_HOST = ENV.fetch('FTP_HOST')
  FTP_LOGIN = ENV.fetch('FTP_LOGIN')
  FTP_PASS = ENV.fetch('FTP_PASS')
end