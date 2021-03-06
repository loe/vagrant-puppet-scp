# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant/puppet/scp/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-puppet-scp"
  spec.version       = Vagrant::Puppet::Scp::VERSION
  spec.authors       = ["W. Andrew Loe III"]
  spec.email         = ["andrew@andrewloe.com"]
  spec.description   = %q{A puppet apply provisioner for Vagrant that uses SCP instead of shared directories.}
  spec.summary       = %q{A puppet apply provisioner for Vagrant that uses SCP instead of shared directories.}
  spec.homepage      = "https://github.com/loe/vagrant-puppet-scp"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
