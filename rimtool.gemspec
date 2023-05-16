# frozen_string_literal: true

require_relative "lib/rimtool/version"

Gem::Specification.new do |spec|
  spec.name = "rimtool"
  spec.version = RimTool::VERSION
  spec.authors = ["Andrey \"Zed\" Zaikin"]
  spec.email = ["zed.0xff@gmail.com"]

  spec.summary = "A set of tools for making better RimWorld mods"
  spec.homepage = "https://github.com/zed-0xff/rimtool"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri"
  spec.add_dependency "md_to_bbcode"
end
