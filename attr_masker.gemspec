# (c) 2017 Ribose Inc.
#

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "attr_masker/version"

Gem::Specification.new do |gem|
  gem.name              = "attr_masker"
  gem.version           = AttrMasker::Version.string
  gem.authors           = ["Ribose Inc."]
  gem.email             = ["open.source@ribose.com"]
  gem.homepage          = "https://github.com/riboseinc/attr_masker"
  gem.summary           = "Masking attributes"
  gem.licenses          = ["MIT"]
  gem.description       = "It is desired to mask certain attributes " \
                          "of certain models by modifying the database."

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency("rails", ">= 4.0.0", "< 5.0")

  gem.add_development_dependency("bundler", "~> 1.15")
  gem.add_development_dependency("combustion", "~> 0.7.0")
  gem.add_development_dependency("pry")
  gem.add_development_dependency("rspec", ">= 3.0")
  gem.add_development_dependency("rubocop", "~> 0.49.1")
  gem.add_development_dependency("sqlite3", "~> 1.3.13")
end
