WITHOUT_ACTIVE_RECORD = ENV.fetch("WITHOUT", "") =~ /\bactiverecord\b/
WITHOUT_MONGOID = ENV.fetch("WITHOUT", "") =~ /\bmongoid\b/
