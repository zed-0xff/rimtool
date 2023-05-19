# frozen_string_literal: true
require_relative "../rimtool"

require 'awesome_print'
require 'fileutils'

include RimTool

desc "list files that will be uploaded, respecting .rimignore files, if any"
task :ls do
  totalsize = 0
  Mod.new(".").each_file do |fname|
    fsize = File.size(fname)
    printf "[.] %5d KB  %s\n", fsize/1024, fname
    totalsize += fsize
  end
  printf "[=] %5d KB\n", totalsize/1024
end

task :mod => :build

task default: [:build]
task release: [:prune, :build, :test, :clean, :ls, :check]

desc "check for any pesky stuff"
task :check do
  # 'rake fix' will need mod.url, so running it before others
  mod = Mod.new(".")
  unless mod.url
    puts "[!] no mod url in About/About.xml".red
    exit 1
  end

  needfix = false
  %w'.gitignore .rimignore README.md LICENSE'.each do |fname|
    unless File.exist?(fname)
      puts "[!] no #{fname}".yellow
      needfix = true
    end
  end
  puts "run 'rake fix' to add missing files" if needfix

  if Dir.exist?("Assemblies")
    csproj_fname = Dir["Source/*.csproj"].first
    Dir["Assemblies/*"].each do |fname|
      if File.directory?(fname)
        puts "[!] dir #{fname} is present".red
        puts "add to PropertyGroup in #{csproj_fname}:"
        puts "    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>"
        puts "    <AppendRuntimeIdentifierToOutputPath>false</AppendRuntimeIdentifierToOutputPath>"
        exit 1
      end
    end
    if File.exist?("Assemblies/0Harmony.dll")
      puts "[!] Assemblies/0Harmony.dll is present".red
      puts "add ExcludeAssets:"
      puts '    <PackageReference Include="Lib.Harmony" Version="2.2.2" ' + 'ExcludeAssets="runtime"'.green + ' />'
      exit 1
    end
    if Dir["Assemblies/*.dll"].size > 1
      puts "[!] too many DLLs in Assemblies".red
      puts "add to Reference/* in #{csproj_fname}:"
      puts "    <Private>False</Private>"
      exit 1
    end
    mod.each_file do |fname|
      if File.extname(fname).downcase == ".pdb"
        puts "[!] PDB files present: #{fname}".red
        puts "add to #{csproj_fname}:"
        puts %Q|    <PropertyGroup Condition=" '$(Configuration)' == 'Release' ">\n      <DebugType>None</DebugType>\n    </PropertyGroup>|
        puts 'or add "*.pdb" to .rimignore'
        exit 1
      end
    end
  end

  if File.exist?("README.md") && File.read("README.md")["FIXME"]
    puts "[!] FIXMEs in README.md".red
    exit 1
  end
end

desc "autofix found issues"
task :fix do
  RimTool.add_template_file(".gitignore")
  RimTool.add_template_file(".rimignore")
  RimTool.add_template_file("LICENSE")
  RimTool.add_template_file("README.md")
end

desc "build Release"
task :build do
  if Dir.exists?("Source")
    Dir.chdir "Source"
    system "dotnet build -c Release", exception: true
    Dir.chdir ".."
  end
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
      .new(ForumRenderer, fenced_code_blocks: true, lax_spacing: false)
      .render(File.read("README.md"))
  end

  desc "render README for steam"
  task :steam do
    puts Mod.new(".").readme.to_steam
  end

  desc "fix img links to other mods"
  task :fix_links do
    d0 = File.read("README.md")
    d1 = d0.dup
    d0.scan(%r_^\[!\[(.+?)\]\((https://steamuserimages.+?)\)\]\(https://steamcommunity\.com/sharedfiles/filedetails/\?id=(\d+)?\)$_)
      .each do |mod_name, mod_img_url, mod_id|
        mod = Mod.find(mod_id)
        if mod.steam_img_url != mod_img_url
          puts "[*] updated #{mod_name.inspect} link"
          d1.gsub!(mod_img_url, mod.steam_img_url)
        end
      end
    if d1 != d0
      File.write "README.md", d1
    end
  end
end

