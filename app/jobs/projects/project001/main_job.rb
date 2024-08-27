class Projects::Project001::MainJob < ApplicationJob
  queue_as :default

  def perform(**args)
    run_id  = Project001::Run.last_id
    offset  = args[:offset]
    limit   = args[:limit]
    country = args[:country]
    Projects::Project001::ImportJob.perform_now(run_id: run_id, country: country, limit: limit, offset: offset)
    Projects::Project001::ImageDownloadJob.perform_now(run_id: run_id, country: country)
    Projects::Project001::FillAdditionJob.perform_now(run_id: run_id, country: country, limit: limit, offset: offset-1)
    FtpService.clear_cache
    # TODO Добавить снятие с публикации отсут. в импорте игр
    # TODO Добавить уведомление о кол-ве проделаной работы
  end
end
