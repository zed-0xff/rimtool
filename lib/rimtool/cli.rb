# frozen_string_literal: true
require "awesome_print"
require "optparse"

module RimTool
  class CLI
    def initialize(argv = ARGV)
      @options = {}
      @args = option_parser.parse!(argv)
    end

    def option_parser
      @option_parser ||=
        OptionParser.new do |opt|
          opt.banner = "Usage: rimtool [options] command..."

          opt.separator "\ncommands:"
          maxlen = @@commands.keys.map(&:to_s).map(&:size).max
          @@commands.each do |c, desc|
            if c.is_a?(Numeric)
              # separator
              opt.separator("\n#{desc}")
            elsif desc
              opt.separator("  %*s  %s" % [-maxlen, c, desc])
            end
          end
        end
    end

    def run!
      if @args.any?
        cmd = @args.shift
        if respond_to?(cmd)
          send(cmd, *@args)
        else
          STDERR.puts "[?] unknown command: #{cmd}"
          exit 1
        end
      else
        puts option_parser.help
        nil
      end
    end

    def self.def_cmd name, desc = nil, &block
      define_method name, block

      name = "#{name} " + block.parameters.map{ |x| x.last.to_s.upcase }.join(' ')

      @@commands ||= {}
      @@commands[name] = desc
    end

    def self.separator text = nil
      @@sep_id ||= 0
      @@commands[@@sep_id] = text
      @@sep_id += 1
    end

    def_cmd :mods, "list all available mods" do
      RimTool::Mod.each do |mod|
        printf "%10d %-50s %s\n", mod.id.to_i, mod.package_id, mod.name
      end
    end

    def_cmd :cd do |id|
      mod = RimTool::Mod.find(id)
      return unless mod
      puts "cd #{mod.path}"
    end

    def_cmd :modinfo, "show all available info for specified mod" do |id|
      mod = RimTool::Mod.find(id)
      return unless mod

      shortpath = mod.path
      printf "%-14s %s\n", "path", shortpath

      keys = [:id, :name, :package_id, nil, :steam_url, :steam_link]
      keys.each do |key|
        unless key
          puts
          next
        end
        printf "%-14s %s\n", key, mod.send(key)
      end
      puts
      puts "steam_img_link " + mod.steam_img_link
      if (d = mod.steam_details)
        ap d
      end
    end

    def_cmd :modlink, "show Markdown workshop link for specified mod(s)" do |*ids|
      ids.each do |id|
        mod = RimTool::Mod.find(id)
        printf("[%s](%s)\n", mod.name, mod.steam_url) if mod
      end
    end

    separator "commands requiring RimWorld running with YADA mod installed and API enabled:"

    def_cmd :yada, "show YADA info for specified mod" do |id|
      mod = RimTool::Mod.find(id)
      pp mod.yada_details
    end

    def_cmd :message, "show in-game message" do |text|
      YADA.message text
    end

    separator

    def_cmd :patches, "list all current Harmony patches" do
      puts YADA.patches
    end

    def_cmd :unpatch, 'unpatch a Harmony patch' do |hash|
      puts YADA.unpatch! hash
    end

    def_cmd :repatch, 'ditto' do |hash|
      puts YADA.repatch! hash
    end

    def_cmd :unpatch_all, "unpatch all patches of specified mod" do |owner|
      puts YADA.unpatch_all! owner
    end
    def_cmd :repatch_all, "ditto" do |owner|
      puts YADA.repatch_all! owner
    end

    def_cmd :bisect do |mask|
      require_relative 'bisector'
      Bisector.new(mask).bisect!
    end

    separator

    def_cmd :disasm, "TBD" do |method|
    end

    def_cmd :subclasses, "TBD" do |clasS|
    end
  end
end
