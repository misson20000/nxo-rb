lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "nxo/version"

Gem::Specification.new do |spec|
  spec.name          = "nxo"
  spec.version       = Nxo::VERSION
  spec.authors       = ["misson20000"]
  spec.email         = ["xenotoad@xenotoad.net"]

  spec.summary       = "Small gem for working with Nintendo Switch executable objects"
  spec.homepage      = "https://github.com/misson20000/nxo-rb"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "lz4-ruby"
  spec.add_development_dependency "bundler", "~> 2.6"
  spec.add_development_dependency "rake", "~> 13.3"
  spec.add_development_dependency "rspec", "~> 3.13"
end
