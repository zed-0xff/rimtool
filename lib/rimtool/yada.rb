# frozen_string_literal: true
require 'nokogiri'
require 'nori'

module RimTool
  class YADA # https://github.com/zed-0xff/RW-YADA/

    PORT = CONFIG['yada_port'] || 8192

    class << self
      def request klass, **params
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.#{klass}") {
            params.each do |k,v|
              case v
              when Array
                xml.send(k) do
                  v.each do |av|
                    xml.send("li", av)
                  end
                end
              else
                xml.send(k, v)
              end
            end
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        resp.body
      end

      def message text
        request "Message", Text: text
      end

      # query steam details if one or more mods
      def query_ugc_details *mods_or_ids
        ids = mods_or_ids.map{ |x| x.is_a?(Mod) ? x.id : x }
        raise "no ids given" if ids.empty?

        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Steam.QueryUGCDetailsRequest") {
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
        request "SetItemDescription",
          PublishedFileId: mod.id,
          Description: mod.readme.to_steam
      end

      # update mod preview image on steam
      def update_item_preview! mod
        request "SetItemPreview",
          PublishedFileId: mod.id,
          PreviewFile: File.expand_path(File.join(mod.path, "About", "Preview.png"))
      end

      # add additional preview image on steam
      def add_item_preview! mod, fname
        request "AddItemPreviewFile",
          PublishedFileId: mod.id,
          PreviewFile: File.expand_path(fname)
      end

      # list Harmony patches
      def patches original: false
        request "Harmony.GetAllPatchedMethods", returnCached: original
      end

      def repatch! *hashes
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Harmony.Repatch") {
            xml.Hashes {
              hashes.each do |hash|
                xml.li hash
              end
            }
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        resp.body
      end

      def unpatch! *hashes
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root("Class" => "YADA.API.Harmony.Unpatch") {
            xml.Hashes {
              hashes.each do |hash|
                xml.li hash
              end
            }
          }
        end
        xml = builder.to_xml
        resp = Net::HTTP.post(URI("http://127.0.0.1:#{PORT}/"), xml)
        resp.body
      end

      def unpatch_all! owner
        request "Harmony.UnpatchAll", Owner: owner
      end

      def repatch_all! owner
        request "Harmony.RepatchAll", Owner: owner
      end

      # fqmn = fully qualified method name :) like "RimWorld.Need::get_MaxLevel"
      def disasm fqmn, original: false
        request "Disasm", fqmn: fqmn, original: original
      end

      def eval expression
        request "Eval", expression: expression
      end
    end # class << self

    class Defs
      def self.Get defType, defName
        YADA.request "Defs.Get", defType: defType, defName: defName
      end
    end
  end
end
