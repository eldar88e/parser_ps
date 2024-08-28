require 'telegram/bot'

class TelegramService
  def initialize(message)
    @message   = message
    @chat_id   = TELEGRAM_CHAT_ID
    @bot_token = TELEGRAM_TOKEN
  end

  def self.call(message)
    new(message).report
  end

  def report
    return unless @message.present?

    if @chat_id.blank? || @bot_token.blank?
      Rails.logger.error 'Telegram chat ID or bot token not set!'
      return
    end

    tg_send
  end

  private

  def tg_send
    [@chat_id.to_s.split(',')].flatten.each do |user_id|
      message_limit = 4000
      message_count = @message.size / message_limit + 1
      Telegram::Bot::Client.run(@bot_token) do |bot|
        message_count.times do
          splitted_text = @message.chars
          splitted_text = %w[D e v |] + splitted_text if Rails.env.development?
          text_part     = splitted_text.shift(message_limit).join
          bot.api.send_message(chat_id: user_id, text: escape(text_part), parse_mode: 'MarkdownV2')
        end
      rescue => e
        Rails.logger.error e.message
      end
    end

    nil
  end

  def escape(text)
    text.gsub(/\[.*?m/, '').gsub(/([-_*\[\]()~`>#+=|{}.!])/, '\\\\\1')
  end
end
