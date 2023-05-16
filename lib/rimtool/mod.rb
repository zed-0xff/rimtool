# frozen_string_literal: true
require "nokogiri"
require "open-uri"

module RimTool
  class Mod
    attr_reader :name, :package_id, :id

    def initialize(path, xml = nil)
      @path = path
      @xml = xml || Nokogiri::XML(open(File.join(path, "About", "About.xml")))
      @name = (@xml/:ModMetaData/:name).first&.text
      @package_id = (@xml/:ModMetaData/:packageId).first&.text
      pub_fname = File.join(path, "About", "PublishedFileId.txt")
      if File.exist?(pub_fname)
        @id = File.read(pub_fname).strip.to_i
      end
    end

    def inspect
      "<RimTool::Mod name=#{@name.inspect} package_id=#{@package_id.inspect} id=#{@id}>"
    end

    def steam_url
      "https://steamcommunity.com/sharedfiles/filedetails/?id=#@id"
    end

    def steam_img_url
      doc = Nokogiri::HTML(URI.open(steam_url))
      img = (doc/"img#previewImageMain")
      return img.attr("src").value if img.any?
      img = (doc/"img#previewImage")
      return img.attr("src").value.sub(/imw=\d+/, "imw=268").sub(/imh=\d+/, "imh=151") if img.any?
      nil
    end

    def steam_img_link
      "[![](%s)](%s)" % [steam_img_url, steam_url]
    end

    def steam_link
      "[%s](%s)" % [name, steam_url]
    end

    def self.find id
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
            puts "  #{path}"
          end
        end
      end
      
      nil
    end
  end
end
