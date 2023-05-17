# frozen_string_literal: true
require "md_to_bbcode"

module RimTool
  class ForumRenderer < MdToBbcode::BbcodeRenderer
    def header(text, header_level)
      case header_level
      when 1
        "\n[center][size=20pt]#{text}[/size][/center]\n"
      when 2
        "\n[color=orange][size=18pt]#{text}[/size][/color]\n"
      else
        "\n\n[color=orange][b]#{text}[/b][/color]\n"
      end
    end

    def git_url
      @git_url ||= `git remote -v`.scan(/git@github\.com:(.+)\.git/).flatten.first
    end

    def image(link, title, alt_text)
      link = "https://github.com/#{git_url}/raw/master/" + link unless link['//']
      "[img]#{link}[/img]"
    end

    def link(link, title, content)
      link = "https://github.com/#{git_url}/raw/master/" + link unless link['//']
      "[url=#{link}]#{content}[/url]"
    end

    def paragraph(text)
      text + "\n\n"
    end
  end

  class SteamRenderer < MdToBbcode::BbcodeRenderer
    def header(text, header_level)
      "\n[h%d]%s[/h%d]\n" % [header_level, text, header_level]
    end

    # add Preview.png only on github
    def image(link, title, alt_text)
      if link =~ %r"^/?About/Preview\."i
        ""
      else
        super
      end
    end

    # add link to steam only on github
    def link(link, title, content)
      if content == ""
        ""
      else
        "[url=#{link}]#{content}[/url]"
      end
    end

    def list(contents, list_type)
      case list_type
      when :ordered
        "[olist]\n#{contents}[/olist]\n"
      else
        "[list]\n#{contents}[/list]\n"
      end + "\n"
    end

    def paragraph(text)
      text + "\n\n"
    end
  end
end
