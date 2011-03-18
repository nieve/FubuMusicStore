namespace :storyteller do
	#TARANTINO = "lib\\tarantino\\Tarantino.DatabaseManager.Console.exe"
	#DBNAME = "FieldBookData"
	#VERSIONEDDB = "FieldBookDataVersioned"
	#DBSCRIPTS = "dbChangeScripts"
	#DBSERVER = "localhost"

	desc "Runs the all StoryTeller Tests"
	task :run => [:runFireFox] #, :runIE]
	
	desc "Runs the all StoryTeller Tests for CI"
	task :runci => [:iisSetup, :runFireFox,:makeIndex] #, :runIE]
	
	desc "Runs the StoryTeller Tests for FireFox"
	task :runFireFox do
		
		Rake::Task["db:resetDev"].invoke
		Rake::Task["storyteller:iisReset"].invoke
		sh "lib/StoryTeller.1.0.1.144/StoryTellerRunner.exe Fieldbook-storyteller.xml FieldBook-results/results.html"
	end
	
	desc "Runs the StoryTeller Tests for InternetExplorer"
	task :runIE do
		Rake::Task["db:resetDev"].invoke
		Rake::Task["storyteller:iisReset"].invoke
		sh "lib/StoryTeller.1.0.1.144/StoryTellerRunner.exe Fieldbook-storyteller-ie.xml FieldBook-results/results-ie.html"
	end
	
	desc "Create Index page for Tests"
	task :makeIndex do
	
	html = "<html><head><title>FieldBook StoryTeller Results</title></head>"
	html += "<body><h1>FieldBook StoryTeller Reults</h1>"
	html += "<ul><li><h3>FieldBook FireFox Results</h3></li><ul>"
	html += "</body></html>"
	
	outputFile = File.new("index.html","w")
	outputFile.write(html)
	outputFile.close
	
	end
	
	
	desc "Setup IIS Site to FieldBook.Interface instance"
	task :iisSetup do
	
		@path = Dir.pwd
		
		puts @path+"/src/FieldBook.Interface"
		
		sh "lib/fieldbookinstaller/fieldbook.exe --init"
		sh "lib/fieldbookinstaller/fieldbook.exe --iis=#{@path}/src/FieldBook.Interface"
	
	end
	
	task :iisReset do
		sh "iisreset"
	end
end