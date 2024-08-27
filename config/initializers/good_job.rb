Rails.application.configure do
  config.good_job.execution_mode = :external
  config.good_job.queues = 'default:5'
  config.good_job.enable_cron = true
  config.good_job.smaller_number_is_higher_priority = true
  config.good_job.time_zone = 'Europe/Moscow'

  # Cron jobs
  config.good_job.cron = {
    main_import_export: {
      cron: "0 8 29 2 *",
      class: "Projects::Project001::MainJob",
      set: { priority: 10 },
      #args: [42, "life"],
      kwargs: { country: :turkish, limit: 5 },
      description: "Update Turkish games"
    }
  }
end
