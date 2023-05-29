# frozen_string_literal: true
require 'nokogiri'
require 'nori'

module RimTool
  class YADA # https://github.com/zed-0xff/RW-YADA/

    PORT = CONFIG['yada_port'] || 8192

    class << self
      def message text
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Request_Message") {
            xml.Text text
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        Nori.new.parse(resp.body)["Response"]
      end

      # query steam details if one or more mods
      def query_ugc_details *mods_or_ids
        ids = mods_or_ids.map{ |x| x.is_a?(Mod) ? x.id : x }
        raise "no ids given" if ids.empty?

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Request_QueryUGCDetailsRequest") {
            xml.ReturnAdditionalPreviews true
            xml.ReturnChildren true
            xml.ReturnKeyValueTags true
            xml.ReturnLongDescription true
            xml.ReturnMetadata true
            xml.ReturnOnlyIDs true
            xml.ReturnTotalOnly true
            xml.PublishedFileIds {
              ids.each do |id|
                xml.li id
              end
            }
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        Nori.new.parse(resp.body)["Response"]
      end

      # update mod description on steam
      def update_item_description! mod
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Request_SetItemDescription") {
            xml.PublishedFileId mod.id
            xml.Description mod.readme.to_steam
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        puts resp.body
      end

      # update mod preview image on steam
      def update_item_preview! mod
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Request_SetItemPreview") {
            xml.PublishedFileId mod.id
            xml.PreviewFile File.expand_path(File.join(mod.path, "About", "Preview.png"))
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        puts resp.body
      end

      # list Harmony patches
      def patches
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Harmony.Request_GetAllPatchedMethods")
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        resp.body
      end

      def repatch! hash
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Harmony.Request_Repatch") {
            xml.Hash hash
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        resp.body
      end

      def unpatch! hash
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Harmony.Request_Unpatch") {
            xml.Hash hash
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        resp.body
      end

      def unpatch_all! owner, req = "Unpatch"
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Harmony.Request_#{req}All") {
            xml.Owner owner
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        resp.body
      end

      def repatch_all! owner
        unpatch_all! owner, "Repatch"
      end
    end
  end
end
