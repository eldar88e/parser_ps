Rails.application.configure do
  config.good_job.execution_mode = :external
  config.good_job.queues = 'default:5'
  config.good_job.enable_cron = true
  config.good_job.smaller_number_is_higher_priority = true
  config.good_job.time_zone = 'Europe/Moscow'

  # Cron jobs
  config.good_job.cron = {
    turkish_import_export: {
      cron: "0 7 * * *",
      class: "Projects::Project001::MainJob",
      set: { priority: 10 },
      #args: [42, "life"],
      kwargs: { country: :turkish, limit: 7000 },
      description: "Update Turkish games"
    },
    ukraine_import_export: {
      cron: "30 7 * * *",
      class: "Projects::Project001::MainJob",
      set: { priority: 10 },
      kwargs: { country: :ukraine, limit: 7000 },
      description: "Update Ukraine games"
    },
    india_import_export: {
      cron: "0 8 * * *",
      class: "Projects::Project001::MainJob",
      set: { priority: 10 },
      kwargs: { country: :india, limit: 7000 },
      description: "Update India games"
    }
  }
end
