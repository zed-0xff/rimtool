# frozen_string_literal: true
require_relative "../rimtool"
require_relative "../rimtool/renderers"

require 'awesome_print'
require 'fileutils'

desc "list files that will be uploaded, respecting .rimignore files, if any"
task :ls do
  printf "[=] %5d KB\n", RimTool.list_dir(".")/1024
end

task :mod => :build

task default: [:build]
task release: [:prune, :build, :test, :clean, :ls, :check]

desc "check for any pesky stuff"
task :check do
  unless File.exist?(".rimignore")
    puts "[!] no .rimignore".yellow
  end
  if Dir.exist?("Assemblies")
    Dir["Assemblies/*"].each do |fname|
      if File.directory?(fname)
        puts "[!] dir #{fname} is present".red
        puts "add to csproj/PropertyGroup:"
        puts "    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>"
        puts "    <AppendRuntimeIdentifierToOutputPath>false</AppendRuntimeIdentifierToOutputPath>"
        exit 1
      end
    end
    if File.exist?("Assemblies/0Harmony.dll")
      puts "[!] Assemblies/0Harmony.dll is present".red
      puts "add ExcludeAssets:"
      puts '    <PackageReference Include="Lib.Harmony" Version="2.2.2" ExcludeAssets="runtime" />'
      exit 1
    end
    if Dir["Assemblies/*.dll"].size > 1
      puts "[!] too many DLLs in Assemblies".red
      puts "add to csproj/Reference/*:"
      puts "    <Private>False</Private>"
      exit 1
    end
    if Dir["Assemblies/*.pdb"].size > 0
      puts "[!] PDB files present".red
      puts "add to csproj:"
      puts %Q|    <PropertyGroup Condition=" '$(Configuration)' == 'Release' ">\n      <DebugType>None</DebugType>\n    </PropertyGroup>|
    end
  end
end

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

