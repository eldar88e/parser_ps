Rails.application.configure do
  TELEGRAM_TOKEN   = ENV.fetch('TELEGRAM_TOKEN')
  TELEGRAM_CHAT_ID = ENV.fetch('TELEGRAM_CHAT_ID')
end