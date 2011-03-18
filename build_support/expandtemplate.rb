require 'erb'
require 'yaml'
include YAMLConfig

class ExpandTemplate
  module GetBinding
    def get_binding
      binding
    end
  end

  include Albacore::Task

  attr_accessor :template, :output, :data_file
  attr_hash :settings

  def execute
    expand_template(@template, @output, @data_file)
  end

  def expand_template(template_file, output_file, data_file)
	
	config = read_config(data_file)
	settings = config
    template = File.read template_file

    vars = OpenStruct.new(settings)
    vars.extend GetBinding
    vars_binding = vars.get_binding

    erb = ERB.new template
    output = erb.result(vars_binding)

    File.open(output_file, "w") do |file|
      puts "Generating #{file.path}"
      file.write(output)
    end
  end
  
private
  
  def read_config(file)
    config = YAML::load(File.open(file, "r"))
    if (config.include?("@include"))
      include_file = File.join(File.dirname(file), config["@include"])
      @logger.debug("Found @include directive. Loading additional data from #{include_file}")      
      config.reject!{|k,v| k == "@include"}
      include_config = read_config(include_file)
      config = deep_merge(include_config, config)
    end
    return config
  end
  
  def deep_merge(first, second)
    # From: http://www.ruby-forum.com/topic/142809
    # Author: Stefan Rusterholz
    merger = proc { |key,v1,v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    first.merge(second, &merger)
  end
  
  def get_config_for_file(original_config, file)
    filename = File.basename(file)
    file_config = original_config[filename]
    if file_config.nil?
      @logger.debug "No config data found for #{filename}. Using local data."
      new_config = original_config
    else
      @logger.debug "Found config data for #{filename}."
      new_config = original_config.merge(file_config)
    end
    new_config
  end
  
end