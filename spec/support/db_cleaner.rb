require "database_cleaner"

RSpec.configure do |config|
  config.before(:suite) do
    strategy = :truncation

    unless WITHOUT_ACTIVE_RECORD
      require "database_cleaner-active_record"
      DatabaseCleaner[:active_record].strategy = strategy
    end

    # Since models are defined dynamically in specs, Database Cleaner is unable
    # to list them and to determine collection names to be cleaned.
    # Therefore, they are specified explicitly here.
    unless WITHOUT_MONGOID
      require "database_cleaner-mongoid"

      strategy =
        if Gem::Version.new(DatabaseCleaner::Mongoid::VERSION) >= Gem::Version.new("2.0.0")
          :deletion
        else
          :truncation
        end

      DatabaseCleaner[:mongoid].strategy = strategy, { only: ["users"] }
    end

    DatabaseCleaner.clean_with(strategy)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
