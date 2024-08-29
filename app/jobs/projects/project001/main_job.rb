# Projects::Project001::MainJob.perform_now(country: :ukraine, limit: 21)

class Projects::Project001::MainJob < ApplicationJob
  queue_as :default

  def perform(**args)
    offset     = args[:offset]
    limit      = args[:limit]
    country    = args[:country] || 'turkish' # TODO убрать || 'turkish'
    class_name = "Project001::Run#{country.to_s.capitalize}"
    klass      = Object.const_get(class_name)
    run_id     = klass.last_id
    Projects::Project001::ImportJob.perform_now(run_id: run_id, country: country, limit: limit, offset: offset)
    Projects::Project001::ImageDownloadJob.perform_now(run_id: run_id, country: country)
    mod_offset = offset ? offset - 1 : nil
    Projects::Project001::FillAdditionJob.perform_now(run_id: run_id, country: country, limit: limit, offset: mod_offset)
    FtpService.clear_cache

    # TODO Добавить снятие с публикации отсут. в импорте игр

    msg = 'Парсер удачно завершил свою работу!'
    msg << " Обработано #{limit} игр." if limit
    TelegramService.call(msg)
  end
end
