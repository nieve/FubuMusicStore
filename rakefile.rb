@compile_target = ENV.include?("compile_target")  ? ENV['compile_target'] : "debug"
require "build_support/BuildUtils.rb"

include FileTest
require 'albacore'
require "build_support/Tarantino.rb"
require 'find'
require 'net/ssh'
require 'net/ftp'
require 'build_support/expandtemplate.rb'

Dir['build_support/*.rake'].each { |file| load(file) }


RESULTS_DIR = "results"
BUILD_NUMBER_BASE = "0.1.0"
PRODUCT = "FubuMusicStore"
COPYRIGHT = 'Copyright 2010 Nine Collective. All rights reserved.';
COMMON_ASSEMBLY_INFO = 'src/CommonAssemblyInfo.cs';
CLR_VERSION = "v4.0.30319"

TARANTINO = "lib\\tarantino\\Tarantino.DatabaseManager.Console.exe"
DBNAME = "DATABASENAME"
VERSIONEDDB = "DATABASEVERSONED"
DBSCRIPTS = "dbChangeScripts"
DBSERVER = "localhost"
@specs = "Specifications"

props = { :archive => "build", :bin => "build/bin", :lib => "build/lib", :serviceFolder => "build/service"}

desc "Compiles, unit tests, generates the database"
task :all => [:default]

desc "**Default**, compiles and runs tests"
task :default => [:compile, :unit_test]

desc "Update the version information for the build"
assemblyinfo :version do |asm|
  asm_version = BUILD_NUMBER_BASE + ".0"
  
  begin
	gittag = `git describe --all --long`.chomp 	# looks something like v0.1.0-63-g92228f4
    gitnumberpart = /-(\d+)-/.match(gittag)
    gitnumber = gitnumberpart.nil? ? '0' : gitnumberpart[1]
    commit = (ENV["BUILD_VCS_NUMBER"].nil? ? `git log -1 --pretty=format:%H` : ENV["BUILD_VCS_NUMBER"])
  rescue
    commit = "git unavailable"
    gitnumber = "0"
  end
  build_number = "#{BUILD_NUMBER_BASE}"
  tc_build_number = ENV["BUILD_NUMBER"]
  puts "##teamcity[buildNumber '#{build_number}.#{tc_build_number}']" unless tc_build_number.nil?
  @buildVersion =  "#{build_number}.#{tc_build_number}"
  
  asm.trademark = commit
  asm.product_name = "#{PRODUCT} ERP - #{@buildVersion}"
  asm.description = build_number
  asm.version = asm_version
  asm.file_version = build_number
  asm.custom_attributes :AssemblyInformationalVersion => @buildVersion
  asm.copyright = COPYRIGHT
  asm.output_file = COMMON_ASSEMBLY_INFO
end

desc "Prepares the working directory for a new build"
task :clean do
	#TODO: do any other tasks required to clean/prepare the working directory
	Dir.mkdir props[:archive] unless exists?(props[:archive])
	
	Dir.mkdir @specs unless exists?(@specs)
	
	basename = props[:archive]
	Dir.foreach(basename) do |f|
	  if f == '.' or f == '..' then next
	  elsif File.directory?(File.join(basename,f)) then FileUtils.rm_rf(File.join(basename,f), :verbose => true)
	  else FileUtils.rm( File.join(basename,f), :verbose => true)
	  end
	end
	
end


desc "Compiles the app"
task :compile => [:clean, :version, :compileSln, :compileAsp] do

end

desc "Compiles the app"
task :compileAsp => [:clean, :version] do
  AspNetCompilerRunner.compile :webPhysDir => "src/FubuMusicStore", :webVirDir => "localhost/xyzzyplugh", :outputPath => props[:archive]
end



desc "Compiles the SLN file"
task :compileSln do
	MSBuildRunner.compile :compilemode => @compile_target, :solutionfile => 'src/FubuMusicStore.sln', :clrversion => CLR_VERSION
end

def copyOutputFiles(fromDir, filePattern, outDir)
  Dir.glob(File.join(fromDir, filePattern)){|file| 		
	copy(file, outDir) if File.file?(file)
  } 
end

desc "Runs unit tests"
task :unit_test => :compileSln do
  runner = NUnitRunner.new :compilemode => @compile_target, :source => 'src', :platform => 'x86', :options => '/framework=4.0.30319'
  runner.executeTests ['FubuMusicStore.Tests','SpecificationTests']
end

desc "Runs Specification Tests"
mspec do |mspec|
		mspec.command ="lib/Machine.Specifications/mspec.exe"
		mspec.assemblies = "src/SpecificationTests/bin/#{@compile_target}/SpecificationTests.dll"
		mspec.options = '--teamcity', '--html Specifications/Index.html' 
end

desc "Target used for the CI server"
task :ci => [:compile, :unit_test,:zip]

desc "Expand the web.config template for the correct environment"
expandtemplate :templateConfig do |tmp|
	tmp.template = "templates/web.config.template"
	tmp.output = "#{props[:archive]}/web.config"
	tmp.data_file = "templates/data/#{@compile_target}.template.data"
end

desc "Expand the rake template for the correct environment"
expandtemplate :templateRake do |tmp|
	tmp.template = "templates/_rake/db.rake.template"
	tmp.output = "#{props[:archive]}/lib/db.rake" 
	tmp.data_file = "templates/data/#{@compile_target}.template.data"
end

desc "ZIPs up the build results"
zip do |zip|
	zip.directories_to_zip = [props[:archive]]
	zip.output_file = "FubuMusicStore-#{@compile_target}-#{@buildVersion}.zip"
	zip.output_path = 'build'
end

def RemoveDirMatchingString(name)
Find.find('./') do |path|
      if File.basename(path) == name
        FileUtils.remove_dir(path, true)
        Find.prune
      end
    end
end

desc "Removes all bin and obj folders from the directory structure"
task :removebin do

   # Remove all bin and obj Directories
    RemoveDirMatchingString('bin')
    RemoveDirMatchingString('obj')
    
end
