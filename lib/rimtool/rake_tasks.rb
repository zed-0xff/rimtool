# frozen_string_literal: true
require_relative "../rimtool"
require_relative "../rimtool/renderers"

require 'fileutils'

desc "list files that will be uploaded, respecting .rimignore files, if any"
task :ls do
  printf "[=] %5d KB\n", RimTool.list_dir(".")/1024
end

task :mod => :release

task default: [:build]
task release: [:prune, :build, :test, :clean, :ls]

desc "build Release"
task :build do
  Dir.chdir "Source"
  system "dotnet build -c Release", exception: true
  Dir.chdir ".."
end

desc "build Debug"
task :debug do
  Dir.chdir "Source"
  system "dotnet build -c Debug", exception: true
  Dir.chdir ".."
end

desc "total clean"
task :prune => :clean do
  FileUtils.rm_rf "Assemblies"
  Rake::Task[:clean].reenable # to be able to call it after test again
end

desc "clean"
task :clean do
  Dir["**/obj"].each{ |x| FileUtils.rm_rf(x) }
  Dir["**/bin"].each{ |x| FileUtils.rm_rf(x) }
end

desc "test"
task :test do
  if Dir.exist?("Test")
    Dir.chdir "Test"
    system "rake", exception: true
    Dir.chdir ".."
  end
end

namespace :readme do
  desc "render README as bbcode"
  task :bb do
    puts Redcarpet::Markdown
      .new(RimTool::ForumRenderer, fenced_code_blocks: true, lax_spacing: false)
      .render(File.read("README.md"))
  end

  desc "render README for steam"
  task :steam do
    puts Redcarpet::Markdown
      .new(RimTool::SteamRenderer, fenced_code_blocks: true, lax_spacing: false)
      .render(File.read("README.md")).strip.gsub("\n\n\n", "\n\n")

    git_url = "https://github.com/" + `git remote -v`.scan(/git@github\.com:(.+)\.git/).flatten.first
    puts "[url=#{git_url}]github[/url]"
  end
end

