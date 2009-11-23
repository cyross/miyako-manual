#encoding: utf-8
# Miyako リファレンスマニュアル生成スクリプト
# 2009 Cyross Makoto

require 'nokogiri'
require 'yaml'
require 'csv'

class Hinagata
  ELEM_LENGTH = 4
  @@e2j = {"class" => "クラス",
           "module" => "モジュール",
           "struct" => "構造体",
           "exception" => "(例外)クラス",
           "main" => "メイン",
          }
          
  @@elems = nil

  def Hinagata.e2j
    @@e2j
  end

  attr_reader :dir, :data
  
  def _init_inner(hash, value)
    value.keys.each{|key|
      if value[key].nil?
        hash[key] = {}
      elsif hash.has_key?(key) && value[key].kind_of?(Hash)
        _init_inner(hash[key], value[key])
      elsif hash.has_key?(key) && value[key].kind_of?(Array)
        hash[key] += value[key]
      else  
        hash[key] = value[key]
      end
    }
  end
  
  private :_init_inner
  
  def initialize(hinagata_dir = ".", yaml_dir = ".", html_dir = ".")
    # ひな形を納めるハッシュを用意
    @hdir = hinagata_dir
    @ydir = yaml_dir
    @tdir = html_dir
    @html = nil
    unless @@elems
      @@elems = {}
      Dir.glob("#{@ydir}/*.yml"){|path|
        hash = YAML.load_file(path)
        _init_inner(@@elems, hash)
      }
    end
  end
  
  def process(name, type)
    @html = _html(_top, name, type)
  end
  
  def output(file)
    File.open("#{@tdir}/#{file}", "w"){|fp|
      @html.write_html_to(fp, :encoding => 'UTF-8', :indent => 2)
    }
  end
  
  def _top
    # 各種ひな形をNokogiriで取得
    Nokogiri::HTML(open(@hdir+"/top.html"))
  end
  
  def _html(top, name, type)
    real_name = /(.+)\<br\>/.match(name) ? $1 : name
    p real_name

    top_title = top.xpath('//title')
    top_title[0].inner_html = "#{name}#{@@e2j[type]}"

    top_node = top.xpath('//div[@id="top_body"]')[0]

    base = _type(type)
    unless type == "main"
      base.xpath("//td[@class=\"#{type}_name\"]")[0].inner_html = name
      base.xpath("//td[@class=\"type_name\"]")[0].children[0].attribute("name").value = "##{real_name}"
    end
    
    top_node << base
    top_node << Nokogiri::XML::Node.new("hr", top)
    
    parts = @@elems[real_name]

    counter = {}
    
    parts.keys.each{|dkey|
      if dkey == "desc"
        parts[dkey].each{|elm|
          if elm[1]
            base.xpath("//td[@class=\"#{elm[0]}\"]")[0].inner_html = elm[1].join("<br>\n")
          else
            base.xpath("//td[@class=\"#{elm[0]}\"]")[0].parent.unlink
          end
        }
        next
      end
      parts[dkey].each{|elm|
        child = _type(dkey)
        name = elm["name"]
        real_str = name
        counter[dkey] = counter[dkey] ? counter[dkey] + 1 : 1
        case dkey
        when "cs"
          real_str = "#{real_name}::#{real_str}"
        when "sm"
          real_str = "#{real_name}.#{real_str}"
        when "ac", "im", "mm"
          real_str = "#{real_name}##{real_str}"
        when "mf"
          real_str = "#{real_name}#.#{real_str}"
        end
        child.xpath("//td[@class=\"real_name\"]")[0].content = real_str
        child.xpath("//td[@class=\"#{dkey}_name\"]")[0].content = name
        child.xpath("//td[@class=\"type_name\"]")[0].children[0].attribute("name").value = "#{name}"
#        puts name
        use_block = {}
        block_format = ""
        return_value = []
        params_str = ""
        params_list = []
        
        elm.keys.each{|key|
#          puts key
#          p elm[key]
          case key
          when "name"
            next
          when "parameters"
            param_base = child.xpath("//td[@class=\"parameters\"]")[0]
            if elm[key].nil? || elm[key].length == 0
              param_base.inner_html = "なし"
            else
              param_top, param_head = _param
              elm[key].each{|param|
                param_hash = Hash.new
                param_body = _param_body
                param.keys.each{|pkey|
                  case pkey
                  when "parameter_name"
                    param_hash[pkey] = param[pkey]
                    param_body.xpath("//td[@class=\"#{pkey}\"]")[0].inner_html = param[pkey]
                  when "param_desc_body", "param_value_body"
                    param[pkey] = param[pkey].nil? ? [""] : param[pkey]
                    param_hash[pkey] = param[pkey].join("/")
                    param_body.xpath("//td[@class=\"#{pkey}\"]")[0].inner_html = param[pkey].join("<br>")
                  when "omit_value_body"
                    if param[pkey]
                      param_hash[pkey] = param[pkey].join("/")
                      param_body.xpath("//td[@class=\"#{pkey}\"]")[0].inner_html = param[pkey].join("<br>")
                    else
                      param_body.xpath("//td[@class=\"#{pkey}\"]")[0].parent.unlink
                      param_body.xpath("//td[@class=\"parameter_name\"]")[0].attribute("rowspan").value = "2"
                    end
                  end
                }
                param_body.children[0].children.each{|pchild| param_head << pchild}
                params_list << param_hash
              }
              param_base << param_top
            end
            next
          when "use_block_body"
            use_block[key] = elm[key]
            unless elm[key]
              child.xpath("//td[@class=\"use_block\"]")[0].parent.unlink
#              child.xpath("//td[@class=\"use_block_need_body\"]")[0].parent.unlink
              child.xpath("//td[@class=\"use_block_format_body\"]")[0].parent.unlink
#              child.xpath("//td[@class=\"use_block\"]")[0].attribute("rowspan").value = "1"
            end
          when "use_block_need_body"
            use_block[key] = elm[key]
            body = child.xpath("//td[@class=\"#{key}\"]")[0]
            body.inner_html = (elm[key] ? "○" : "×") if body
          when "use_block_format_body"
            block_format = elm[key] ? elm[key] : [""]
            body = child.xpath("//td[@class=\"#{key}\"]")[0]
            body.inner_html = block_format.join("<br>\n") if body
          when "return_type"
            return_value = elm[key] ? elm[key] : ["nil"]
          when "return_value_body"
            if elm[key]
              child.xpath("//td[@class=\"#{key}\"]")[0].inner_html = elm[key].join("<br>\n")
            else
              child.xpath("//td[@class=\"#{key}\"]")[0].inner_html = "なし"
            end
          else
            if elm[key]
              child.xpath("//td[@class=\"#{key}\"]")[0].inner_html = elm[key].join("<br>\n")
            else
              child.xpath("//td[@class=\"#{key}\"]")[0].parent.unlink
            end
          end
        }

        param_str = params_list.map{|ph|
          ov = ph["omit_value_body"]
          ph["parameter_name"] + ((ov.nil? || ov == "") ? "" : (" = " + ov))
        }.join(",")
        param_str = "(#{param_str})" if param_str.length > 0
        
        block_pattern = [""]
        if use_block["use_block_body"]
          block_format.each{|fmt|
            block_pattern << fmt if fmt != ""
          }
          block_pattern.shift if use_block["use_block_need_body"]
        end

        base_str = "#{real_str}#{param_str}"

        formats = block_pattern.map{|bp|
          "#{base_str}#{bp}"
        }
        
        formats = return_value.map{|rv|
          formats.map{|fm|
            "#{fm} #-> #{rv}"
          }
        }.flatten

        format_node = child.xpath("//td[@class=\"format_body\"]")[0]
        format_node.inner_html = formats.join("<br>\n") if format_node
        
        top_node << child
        top_node << Nokogiri::XML::Node.new("hr", top)
        br = counter[dkey] % ELEM_LENGTH == 0 ? "<br>" : ""
        base.xpath("//td[@class=\"#{dkey}_body\"]")[0].inner_html += "<a href=\"##{name}\">#{name}</a>&nbsp;#{br}\n"
      }
    }

    # フッタを生成
    last_update = Nokogiri::XML::Node.new("div", top)
    last_update["style"] = "text-align: right; font-weight: bold; font-type: italic;"
    last_update.content = "last updated " + Time.now.strftime("%Y/%m/%d")
    top_node << last_update

    top
  end
  
  def _param
    params = Nokogiri::HTML(open(@hdir+"/parameters.html"))
    top = params.xpath('//table[@class="parameter"]')[0]
    head = top.children[0]
    [top, head]
  end
  
  def _param_body
    param = Nokogiri::HTML(open(@hdir+"/parameter.html"))
    param.xpath('//table[@class="columns"]')[0]
  end
  
  def _type(type)
    nodes = Nokogiri::HTML(open(@hdir+"/#{type}.html"))
    nodes.xpath('//table[@class="ref_body"]')[0]
  end
  
  private :_top, :_html, :_type
end

if $0 == __FILE__
  hina = "./hinagata"
  yaml = "./src"
  html = "./ref"

  CSV.read("./files.csv").each{|list|
    file = list.shift
    ref = Hinagata.new(hina, yaml, html)
    ref.process(*list)
    ref.output(file)
  }
end