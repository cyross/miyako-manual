#encoding: utf-8

require 'yaml'
require 'csv'
require 'optparse'

class Converter
  @@descs = {
    "main" => lambda{
      {
        "desc_body" => [""],
        "requires_body" => [""]
      }
    },
    "class" => lambda{
      {
        "desc_body" => [""],
        "requires_body" => [""],
        "inherited_body" => [""],
        "mixin_body" => [""],
        "delegated_body" => [""],
        "class_body" => [""],
        "inherits_body" => [""],
        "delegats_body" => [""]
      }
    },
    "module" => lambda{
      {
        "desc_body" => [""],
        "requires_body" => [""],
        "mixin_body" => [""],
        "class_body" => [""],
        "module_body" => [""]
      }
    },
    "struct" => lambda{
      {
        "desc_body" => [""],
        "requires_body" => [""],
        "inherited_body" => [""],
        "mixin_body" => [""],
        "delegated_body" => [""],
        "class_body" => [""],
        "inherits_body" => [""],
        "delegats_body" => [""]
      }
    },
    "exception" => lambda{
      {
        "desc_body" => [""],
        "inherited_body" => [""]
      }
    },
    
    "ac" => lambda{
      {
        "desc_body" => [""],
        "format_body" => [""],
        "access_body" => [""],
        "value_body" => [""],
        "examples_body" => [""],
        "reference_body" => [""]
      }
    },
    "cs" => lambda{
      {
        "desc_body" => [""],
        "value_body" => [""],
        "examples_body" => [""],
        "reference_body" => [""]
      }
    },
    "gv" => lambda{
      {
        "desc_body" => [""],
        "value_body" => [""],
        "default_body" => [""],
        "examples_body" => [""],
        "reference_body" => [""]
      }
    },
    "im" => lambda{
      {
        "desc_body" => [""],
        "parameters" => [
          {
            "parameter_name"=>"",
            "param_desc_body"=>[""],
            "param_value_body"=>[""],
            "omit_value_body"=>[""]
          },
          {
            "parameter_name"=>"",
            "param_desc_body"=>[""],
            "param_value_body"=>[""],
            "omit_value_body"=>[""]
          }
        ],
        "use_block_body" => false,
        "use_block_need_body" => false,
        "use_block_format_body" => [""],
        "return_type" => [""],
        "return_value_body" => [""],
        "access_body" => [""],
        "examples_body" => [""],
        "reference_body" => [""]
      }
    },
    "mf" => lambda{
      {
        "desc_body" => [""],
        "parameters" => [
          {
            "parameter_name"=>"",
            "param_desc_body"=>[""],
            "param_value_body"=>[""],
            "omit_value_body"=>[""]
          },
          {
            "parameter_name"=>"",
            "param_desc_body"=>[""],
            "param_value_body"=>[""],
            "omit_value_body"=>[""]
          }
        ],
        "use_block_body" => false,
        "use_block_need_body" => false,
        "use_block_format_body" => [""],
        "return_type" => [""],
        "return_value_body" => [""],
        "access_body" => [""],
        "examples_body" => [""],
        "reference_body" => [""]
      }
    },
    "mm" => lambda{
      {
        "desc_body" => [""],
        "value_body"=>[""],
        "omit_value_body"=>[""],
        "examples_body" => [""],
        "reference_body" => [""]
      }
    },
    "sm" => lambda{
      {
        "desc_body" => [""],
        "parameters" => [
          {
            "parameter_name"=>"",
            "param_desc_body"=>[""],
            "param_value_body"=>[""],
            "omit_value_body"=>[""]
          },
          {
            "parameter_name"=>"",
            "param_desc_body"=>[""],
            "param_value_body"=>[""],
            "omit_value_body"=>[""]
          }
        ],
        "use_block_body" => false,
        "use_block_need_body" => false,
        "use_block_format_body" => [""],
        "return_type" => [""],
        "return_value_body" => [""],
        "access_body" => [""],
        "examples_body" => [""],
        "reference_body" => [""]
      }
    }
  }

  def initialize(hash)
    @hash = hash
    @in_path = nil
    @out_path = nil
  end
  
  def convert(in_path, out_path)
    hash = YAML.load_file(in_path)
    hash.keys.each{|name|
      type = @hash[name]
      puts "#{name}=>#{type}"
      hash[name] = {} unless hash[name]
      hash[name].keys.each{|cate|
        arr = []
        hash[name][cate].each{|elem|
          desc = {"name"=>elem}
          tmp = @@descs[cate].call
          tmp.keys.each{|key| desc[key] = tmp[key]}
          arr << desc
        }
        hash[name][cate] = arr
      }
      hash[name]["desc"] = @@descs[type].call if @@descs.include?(type)
    }
    File.open(out_path, "w"){|f| YAML.dump(hash, f)}
  end
end

if $0 == __FILE__
  in_dir = "./src0"
  out_dir = "./src"
  c2t = {}
  CSV.read("./files.csv").each{|list|
    real_name = /(.+)\<br\>/.match(list[1]) ? $1 : list[1]
    c2t[real_name] = list[2]
  }
  Dir.glob("#{in_dir}/*.yml"){|in_path|
    out_path = "#{out_dir}/#{File.basename(in_path)}"
    Converter.new(c2t).convert(in_path, out_path)
  }
end