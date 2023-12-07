# frozen_string_literal: true

module RimTool
  class Mod
    class Readme
      def initialize text, mod
        @text = text
        @mod = mod
      end

      def stub_mod
        if CONFIG['stub_mod_id']
          @stub_mod ||= Mod.find(CONFIG['stub_mod_id'])
        else
          nil
        end
      end

      def _find_preview mod, img_bname
        return nil if mod.nil? || img_bname.nil?

        x = mod.yada_details&.dig("AdditionalPreviews", "li")
        case x
        when Array
          # ok
        when Hash
          x = [x]
        when nil
          return nil
        else
          raise "unexpected: #{x.inspect}"
        end
        x.find{ |x| x['OriginalFileName'] == img_bname }
      end

      def to_steam
        Redcarpet::Markdown
          .new(RimTool::SteamRenderer, fenced_code_blocks: true, lax_spacing: false)
          .render(File.read("README.md"))
          .strip
          .gsub("\n\n\n", "\n\n")
          .gsub("[/img][/url]\n[url", "[/img][/url] [url") # make "You may also like" images block horizontal
          .gsub("\n\n[olist]", "\n[olist]")                # lists have too big default upper margin# 
          .gsub("\n\n[list]",  "\n[list]")
          .gsub(%r_\[img\]((?!http).+?)\[/img\]_) do |x|
            img_bname = File.basename($1) # "screens/yada6.jpg" -> "yada6.jpg"
            if (steam_img = _find_preview(@mod, img_bname))
              "[img]" + steam_img['URLOrVideoID'] + "[/img]"
            elsif (steam_img = _find_preview(stub_mod, img_bname))
              "[img]" + steam_img['URLOrVideoID'] + "[/img]"
            else
              STDERR.puts "[?] img #{img_bname} not found on steam".yellow
              x
            end
          end
      end

      def to_about_xml
        Redcarpet::Markdown
          .new(RimTool::AboutXMLRenderer)
          .render(File.read("README.md"))
          .sub("<color=#1a8bff><b>You may also like...</b></color>", "")
          .strip
          .gsub(/\n{3,}/, "\n\n")
      end
    end
  end
end
