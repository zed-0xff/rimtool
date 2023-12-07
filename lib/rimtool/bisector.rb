# frozen_string_literal: true

module RimTool
  class Bisector
    attr_reader :mask

    def initialize mask, verbose: false
      @mask = mask
      @verbose = verbose
    end

    def bisect!
      patches = []

      if mask[' ']
        patches = mask.split
      else
        xml = Nokogiri::XML(YADA.patches)
        xml.xpath("//Method").each do |m|
          (m/:Patch).each do |p|
            a = [m['Class'], m['Name'], p['PatchClass']]
            patches << p['Hash'] if a.any?{ |x| x[mask] }
          end
        end
      end

      _bisect patches
    end

    private

    def _bisect patches
      if patches.size == 0
        puts "[?] nothing found"
        return
      end
      if patches.size == 1
        puts "[=] found: #{patches[0]}".green
        return
      end

      msg = "[*] #{patches.size} patches to go"
      if patches.size < 4
        msg << " (" << patches.join(' ') << ")"
      end
      puts msg

      l = patches.shift(patches.size/2)
      r = patches

      unpatch(l)
      good = nil

      begin
        good = ask
      ensure
        repatch(l)
      end

      if good.nil?
        puts "[x] aborting.."
        return
      end

      if good
        _bisect(l)
      else
        _bisect(r)
      end
    end

    def unpatch(patches)
      puts "[d] unpatching " + patches.join(' ') if @verbose
      YADA.unpatch!(*patches)
    end

    def repatch(patches)
      YADA.repatch!(*patches)
    end

    def ask
      STDOUT << "[.] is it good? [y/n/q] "
      STDOUT.sync
      loop do
        l = STDIN.gets.to_s.strip
        case l
        when 'y'
          return true
        when 'n'
          return false
        when 'q'
          return nil
        end
      end
    end
  end
end
