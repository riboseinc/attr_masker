require "database_cleaner"

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner[:active_record].strategy = :truncation
    # Since models are defined dynamically in specs, Database Cleaner is unable
    # to list them and to determine collection names to be cleaned.
    # Therefore, they are specified explicitly here.
    DatabaseCleaner[:mongoid].strategy = :truncation, { only: "users" }

    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
