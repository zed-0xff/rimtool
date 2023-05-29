# frozen_string_literal: true
require "nokogiri"
require "open-uri"
require "net/http"
require "json"

module RimTool
  class Mod
    attr_reader :path, :name, :package_id, :author, :url, :id

    def initialize(path, xml = nil)
      @path = path
      @xml = xml || Nokogiri::XML(open(File.join(path, "About", "About.xml")))
      @name = @xml.xpath("//ModMetaData/name").text
      @author = @xml.xpath("//ModMetaData/author").text
      @url = @xml.xpath("//ModMetaData/url").text
      @package_id = @xml.xpath("//ModMetaData/packageId").text
      pub_fname = File.join(path, "About", "PublishedFileId.txt")
      if File.exist?(pub_fname)
        @id = File.read(pub_fname).strip.to_i
      end
    end
    
    def readme
      @readme ||= Readme.new(File.read(File.join(path, "README.md")), self)
    end

    def github_url
      return url if url.start_with?("https://github.com/")
      nil
    end

    def steam_id
      id
    end

    def inspect
      "<RimTool::Mod name=#{@name.inspect} package_id=#{@package_id.inspect} id=#{@id}>"
    end

    def steam_url
      "https://steamcommunity.com/sharedfiles/filedetails/?id=#@id"
    end

    def yada_details
      @yada_details ||= YADA.query_ugc_details(id).dig("Results", "li")
    end

    # nice tool: https://steamapi.xpaw.me/
    # curl 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/' -X 'POST' --data 'key=XXX&itemcount=1&publishedfileids%5B0%5D=2961708299'
    def steam_details
      return nil unless CONFIG['steam_web_api_key']

      @steam_details ||=
        begin
          uri = URI("https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/")
          req = Net::HTTP.post_form(uri, key: CONFIG['steam_web_api_key'], itemcount: 1, "publishedfileids[0]" => id)
          r = JSON.parse(req.body)
          r.dig('response', 'publishedfiledetails', 0) || r
        end
    end

    def steam_img_url
      if steam_details
        return steam_details['preview_url'] + "?imw=268&imh=151&ima=fit&impolicy=Letterbox"
      end

      doc = Nokogiri::HTML(URI.open(steam_url))
      img = (doc/"img#previewImageMain")
      return img.attr("src").value if img.any?

      img = (doc/"img#previewImage")
      return img.attr("src").value.sub(/imw=\d+/, "imw=268").sub(/imh=\d+/, "imh=151") if img.any?
      nil
    end

    def steam_img_link
      "[![%s](%s)](%s)" % [name, steam_img_url, steam_url]
    end

    def steam_link
      "[%s](%s)" % [name, steam_url]
    end

    # iterate over mod files, respecting .rimignore, if any
    def each_file dir=path, ignores = Set.new([".", ".."]), &block
      rimignore_fname = File.join(dir, ".rimignore")
      if File.exist?(rimignore_fname)
        ignores = ignores.dup + Set.new(File.readlines(rimignore_fname).map{ |line| line[0] == "#" ? "" : line.strip }.uniq).delete("")
      end

      globs = ignores.find_all{ |i| i[/[?*]/] }
      Dir.foreach(dir).to_a
        .delete_if{ |fn| ignores.include?(fn) }
        .delete_if{ |fn| globs.any?{ |g| File.fnmatch(g, fn, File::FNM_DOTMATCH) } }
        .each do |fn|
          pathname = File.join(dir, fn)
          if File.directory?(pathname)
            each_file(pathname, ignores, &block)
          else
            yield pathname
          end
        end
    end

    def self.each(&block)
      e = Enumerator.new do |y|
        seen = Set.new
        MOD_DIRS.each do |dirname|
          Dir.each_child(dirname) do |fn|
            mod_dir = File.join(dirname, fn)
            next unless File.exist?(File.join(mod_dir, "About", "About.xml"))

            mod = Mod.new(mod_dir)
            next if mod.id && seen.include?(mod.id)

            y << mod
          end
        end
        nil
      end
      block_given? ? e.each(&block) : e
    end

    def self.find_all &block
      each.find_all(&block)
    end

    def self.find id=nil, &block
      if block_given?
        each do |mod|
          return mod if block.call(mod)
        end
        return nil
      end
      
      return nil unless id

      id = id.to_s

      if id == "."
        return Mod.new(".")
      end

      # fast search by mod steam id as dirname
      MOD_DIRS.each do |dirname|
        path = File.join(dirname, id)
        if File.exist?(path)
          return Mod.new(path)
        end
      end

      xmls = {}

      # slower search by mod packageId
      MOD_DIRS.each do |dirname|
        Dir[File.join(dirname, "*")].each do |path|
          xml_fname = File.join(path, "About", "About.xml")
          next unless File.exist?(xml_fname)

          xml = Nokogiri::XML(open(xml_fname))
          xmls[path] = xml
          if (xml/:ModMetaData/:packageId).first&.text == id || (xml/:ModMetaData/:name).first&.text == id
            return Mod.new(path, xml)
          end
        end
      end

      # slower search by mod steam id from About/PublishedFileId.txt
      MOD_DIRS.each do |dirname|
        Dir[File.join(dirname, "*")].each do |path|
          pub_fname = File.join(path, "About", "PublishedFileId.txt")
          next unless File.exist?(pub_fname)

          if File.read(pub_fname).strip == id
            return Mod.new(path)
          end
        end
      end

      if id.size >= 3
        # partial modname match
        id = id.downcase
        found = []
        xmls.each do |path, xml|
          modname = (xml/:ModMetaData/:name).first&.text&.downcase
          if modname && modname[id]
            found << [path, xml]
          end
        end
        if found.size == 1
          return Mod.new(found[0][0])
        else
          puts "[?] #{found.size} mods found:"
          found.each do |path, xml|
            modname = (xml/:ModMetaData/:name).first&.text&.downcase
            printf "  %s  %s\n", path, modname
          end
        end
      end
      
      nil
    end
  end
end
