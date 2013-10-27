# -*- encoding: utf-8 -*-
# Confidential and proprietary trade secret material of Ribose, Inc.
# (c) 2013 Ribose, Inc. as unpublished work.
#

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'indigo/attr_masked/version'

Gem::Specification.new do |gem|
  gem.name              = 'indigo-attr_masked'
  gem.version           = Indigo::AttrMasked::Version.string
  gem.authors           = ['Ribose, Inc.']
  gem.email             = ['info@ribose.com']
  gem.homepage          = ''
  gem.summary           = 'Masking attributes, the Indigo way'
  gem.description       = <<EOF
It is desired to mask certain attributes of certain models by modifying the 
database.
EOF

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('rails', '>= 3.0.0')
  gem.add_dependency('rspec', '>= 2.0')
end
