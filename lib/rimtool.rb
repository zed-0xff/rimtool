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
require_relative "rimtool/mod/readme"
require_relative "rimtool/renderers"
require_relative "rimtool/yada"
