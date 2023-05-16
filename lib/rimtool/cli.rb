# frozen_string_literal: true

module RimTool
  class CLI
    attr_reader :argv

    def initialize argv = ARGV
      @argv = argv
    end

    def run!
      case argv.first
      when 'modinfo'
        mod = RimTool::Mod.find(argv[1])
        return unless mod

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
      when 'modlink'
        mod = RimTool::Mod.find(argv[1])
        if mod
          printf "[%s](%s)\n", mod.name, mod.steam_url
        end
      end
    end
  end
end