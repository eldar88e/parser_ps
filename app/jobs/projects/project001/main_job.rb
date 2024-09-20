# Projects::Project001::MainJob.perform_now(country: :ukraine, limit: 21)

class Projects::Project001::MainJob < ApplicationJob
  queue_as :default

  def perform(**args)
    offset     = args[:offset]
    limit      = args[:limit]
    country    = args[:country]
    class_name = "Project001::Run#{country.to_s.capitalize}"
    run_class  = Object.const_get(class_name)
    run_id     = run_class.last_id
    saved, updated, restored, upd_menuidx =
      Projects::Project001::ImportJob.perform_now(run_id: run_id, country: country, limit: limit, offset: offset)
    Projects::Project001::FillAdditionJob.perform_later(run_id: run_id, country: country)
    Projects::Project001::ImageDownloadJob.perform_now(run_id: run_id, country: country)

    not_touched_additions = Project001::BIblockElement.not_touched(run_id, country)
    deactivated           = not_touched_additions.update_all(ACTIVE: 'N')

    FtpService.clear_cache
    run_class.finish

    msg = "Парсер для #{country} удачно завершил свою работу!"
    msg << "\nСохранено #{saved} новых игр." unless saved.zero?
    msg << "\nОбновлено Меню индекс #{upd_menuidx} игр." if upd_menuidx > 0
    msg << "\nОбновлено #{updated} старых игр." unless updated.zero?
    msg << "\nВосстановлено #{restored} старых игр." unless restored.zero?
    msg << "\nДеактивировано #{deactivated} игр." # unless deactivated.zero? TODO устранить
    TelegramService.call(msg)
  rescue => e
    TelegramService.call("#{class_name}. Error: #{e.message}")
    raise
  end
end
