# Projects::Project001::MainJob.perform_now(country: :ukraine, limit: 21)

class Projects::Project001::MainJob < ApplicationJob
  queue_as :default

  def perform(**args)
    offset         = args[:offset]
    limit          = args[:limit]
    country        = args[:country] || 'turkish' # TODO убрать || 'turkish'
    class_name     = "Project001::Run#{country.to_s.capitalize}"
    run_class      = Object.const_get(class_name)
    run_id         = run_class.last_id
    saved, updated, restored = Projects::Project001::ImportJob.perform_now(run_id: run_id, country: country, limit: limit, offset: offset)
    uploaded_image = Projects::Project001::ImageDownloadJob.perform_now(run_id: run_id, country: country)
    Projects::Project001::FillAdditionJob.perform_now(run_id: run_id, country: country)

    not_touched_additions = Project001::Addition.not_touched(run_id, country)
    deactivated = 0
    not_touched_additions.each { |i| deactivated += 1; i.b_iblock_element.update(ACTIVE: 'N') }

    FtpService.clear_cache

    run_class.finish

    msg = 'Парсер удачно завершил свою работу!'
    msg << "\nСохранено #{saved} новых игр." unless saved.zero?
    msg << "\nОбновлено #{updated} старых игр." unless updated.zero?
    msg << "\nВосстановлено #{restored} старых игр." unless restored.zero?
    msg << "\nЗагружено #{uploaded_image} картинок." unless uploaded_image.zero?
    msg << "\nДеактивировано #{deactivated} игр." unless deactivated.zero?
    TelegramService.call(msg)
  rescue => e
    TelegramService.call("#{class_name}. Error: #{e.message}")
    raise
  end
end
