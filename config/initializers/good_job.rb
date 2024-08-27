Rails.application.configure do
  config.good_job.execution_mode = :external
  config.good_job.queues = 'default:5'
  config.good_job.enable_cron = true
  config.good_job.smaller_number_is_higher_priority = true
  config.good_job.time_zone = 'Europe/Moscow'

  # Cron jobs
  config.good_job.cron = {
    check_avito_shedules: {
      cron: "30 8-23 * * *",
      class: "Projects::Project001::MainJob",
      set: { priority: 10 },
      #args: [42, "life"],
      #kwargs: { user_id: ENV.fetch("USER_ID") { 1 }.to_i },
      description: "Update Turkish games"
    }
  }
end
