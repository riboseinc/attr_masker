require "database_cleaner"

RSpec.configure do |config|
  config.before(:suite) do
    unless WITHOUT_ACTIVE_RECORD
      DatabaseCleaner[:active_record].strategy = :truncation
    end

    # Since models are defined dynamically in specs, Database Cleaner is unable
    # to list them and to determine collection names to be cleaned.
    # Therefore, they are specified explicitly here.
    unless WITHOUT_MONGOID
      DatabaseCleaner[:mongoid].strategy = :truncation, { only: "users" }
    end

    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
