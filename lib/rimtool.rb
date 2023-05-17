# frozen_string_literal: true

require_relative "rimtool/version"
require "yaml"
require "set"
require "erb"

module RimTool
  CONFIG_FNAME = File.expand_path("~/.rimtool/config.yml")
  CONFIG       = File.exist?(CONFIG_FNAME) ? YAML::load_file(CONFIG_FNAME) : {}

  TEMPLATE_DIRS = (Array(CONFIG['template_dirs']) + [
    "~/.rimtool",
    File.join(File.dirname(__FILE__), "..", "templates")
  ]).map{ |x| File.expand_path(x) }

  MOD_DIRS = (CONFIG['mod_dirs'] || [
    "~/Library/Application Support/Steam/steamapps/workshop/content/294100",
    "~/Library/Application Support/Steam/steamapps/common/RimWorld/RimWorldMac.app/Mods",
  ]).map{ |x| File.expand_path(x) }

  # list dir contents respecting .rimignore, if any
  def self.list_dir dir, ignores = Set.new([".", ".."])
    rimignore_fname = File.join(dir, ".rimignore")
    if File.exist?(rimignore_fname)
      ignores = ignores.dup + Set.new(File.readlines(rimignore_fname).map{ |line| line[0] == "#" ? "" : line.strip }.uniq).delete("")
    end

    r = 0
    globs = ignores.find_all{ |i| i[/[?*]/] }
    Dir.foreach(dir).to_a
      .delete_if{ |fn| ignores.include?(fn) }
      .delete_if{ |fn| globs.any?{ |g| File.fnmatch(g, fn, File::FNM_DOTMATCH) } }
      .each do |fn|
        pathname = File.join(dir, fn)
        if File.directory?(pathname)
          r += list_dir(pathname, ignores)
        else
          fsize = File.size(pathname)
          printf "[.] %5d KB  %s\n", fsize/1024, pathname
          r += fsize
        end
      end
    r
  end

  def self.add_template_file fname
    return if File.exists?(fname)

    TEMPLATE_DIRS.each do |td|
      src = File.join(td, fname)
      if File.exists?(src)
        FileUtils.cp(src, fname)
        puts "[.] created #{fname}"
        return
      end

      erbsrc = src + ".erb"
      if File.exists?(erbsrc)
        mod = Mod.new(".")
        File.write(fname, ERB.new(File.read(erbsrc)).result(binding))
        puts "[.] created #{fname}"
        return
      end
    end
  end
end

require_relative "rimtool/mod"
