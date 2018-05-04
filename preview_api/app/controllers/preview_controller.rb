class PreviewController < ApplicationController
	def index
		json = params[:_json] 
		if json.is_a? String 
			json = JSON.parse json
			puts "ty: #{json.class}"
		end
		puts "JJSSSON: #{json}"
		previewGenerator = json[0]["option"]
		puts "previewGenerator: #{previewGenerator}"
		json.delete_at(0)
		if previewGenerator == "html"
			htmlPreview(json)
		else
			CasparCGPreview(json)
		end
	end

	#def status
    #    render json: {status: "success",filepath: "http://10.0.12.119:8004/preview/CasparCGServer/media/#{params['videoName']}_pre.mov"}, status: :ok 
    #end

    def status(videoName)
    	FileUtils.mkdir_p(File.dirname("public/videos"))
    	File.open("#{Rails.root}/public/videos/#{videoName}_pre.mov", "wb") do |f| 
			f.write HTTParty.get("http://10.0.12.119:8004/preview/CasparCGServer/media/#{videoName}_pre.mov").body
		end
        return "http://10.0.12.119:3000/videos/#{videoName}_pre.mov"
    end

    def show_preview
        @filepath = status(params['videoName'])
        #@filepath = "http://10.0.12.119:3000/videos/b_pre.mov"
        puts "fileeee: #{@filepath}"
    end

	private 
	def CasparCGPreview(json1)
		require 'socket'
		require 'open-uri'
		require 'etc'
		require 'rmagick'
		require 'json'
		require "httparty"

		host = '127.0.0.1'     
		port = 5250  
		response = "" 
		adWidth = Array.new()
		adHeight = Array.new()
		adFolder = Array.new()
		adX = Array.new()
		adY = Array.new()
		msg = ""
		casparCGDirectory = "#{Etc.getpwuid.dir}"+'/preview/CasparCGServer/media/'
		baseURI = "http://10.0.12.119:3000/"	
		casparDir = "/preview/CasparCGServer/media/"
		result = Hash.new
		json1.each do |asset|
			videoName = File.basename(asset['filename'],File.extname(asset['filename']))
			extension = File.extname(asset['filename'])
			#File.write casparCGDirectory+videoName+extension, open(asset["filename"]).read
			File.open(casparCGDirectory+videoName+extension, "wb") do |f| 
			 	f.write HTTParty.get(asset['filename']).body
			end

			asset['filename']=videoName
			i = -1
			asset['ad'].each do |ads|
				i+=1
				adX[i] = 0
				adY[i] = 0
 				if !ads['adname'].include? ".zip"
					adFolder[i] = ""
					adname = File.basename(ads['adname'],File.extname(ads['adname']))
					extension = File.extname(ads['adname'])
					#File.write casparCGDirectory+adname+extension, open(ads["adname"]).read
					File.open(casparCGDirectory+adname+extension, "wb") do |f| 
			 			f.write HTTParty.get(ads['adname']).body
					end
					img = Magick::Image.ping(casparCGDirectory+adname+extension ).first
					adWidth[i] = img.columns/1920.0
					adHeight[i] = img.rows/1080.0
					ads['adname'] = adname
				else
					adFolder[i] = "tga"+"#{i}"
					#content = open('http://localhost:3000/foobar.zip')
					content = open(ads["adname"])
					adname = File.basename(ads['adname'],File.extname(ads['adname']))
					open(casparCGDirectory+"#{adFolder[i]}.zip", 'wb') do |fo|
					  fo.print open(ads["adname"]).read
					end

					FileUtils::mkdir_p casparCGDirectory+"#{adFolder[i]}"
					destination = casparCGDirectory+"#{adFolder[i]}"
					file = casparCGDirectory+"#{adFolder[i]}.zip"
					Zip::File.open(file) do |zip_file|
					    zip_file.each do |f|
					      fpath = File.join(destination, f.name)
					      zip_file.extract(f, fpath) unless File.exist?(fpath)
					    end
					end

					tga_source = casparCGDirectory+"#{adFolder[i]}/tga"

					images = Array.new() 
					images = Dir["#{tga_source}/*.tga"]
					images.sort!
					midImage = images[images.length/2]
					img = Magick::Image.ping(midImage).first
					adWidth[i] = img.columns/1920.0
					adHeight[i] = img.rows/1080.0

					start_index = 0 
					w = 0
					h = 0
					begin
						img = Magick::Image.ping(images[start_index]).first
						w = img.columns
						h = img.rows
						start_index += 1
					end until w > 1 and h > 1
					`ffmpeg -r #{ads['fps']} -start_number #{start_index-1} -i #{tga_source}/img_%05d.tga -y -vcodec rawvideo -pix_fmt rgba #{casparCGDirectory}#{adFolder[i]}.mov`
					ads['adname'] = adFolder[i]
					source = casparCGDirectory+"#{adFolder[i]}"
					FileUtils.remove_dir(source)
					FileUtils.remove_dir(file)
				end
			end

			response=""
			layer = 2
			adNum = -1
			numofAds = asset['ad'].length

			overlap = Array.new()
			for i in 0..numofAds-1
				overlap[i] = false
				for j in 0..numofAds-1
					if asset['ad'][i]['offset'] > asset['ad'][j]['offset'] and asset['ad'][i]['offset'] < asset['ad'][j]['offset']+asset['ad'][j]['duration']
						overlap[i] = true
						break
					end
				end
			end


			sleepDur = asset['ad'][0]['offset']
			p=Array.new()

			socket = TCPSocket.new(host,port)
			i = 0
			#socket.write("ADD 1 FILE #{Rails.root}/public/videos/#{asset['filename']}_pre.mov"+"\r\n")
			socket.write("ADD 1 FILE #{asset['filename']}_pre.mov"+"\r\n")
			response = response+socket.gets
			nextAd = false
			asset['ad'].each do |ads|
				adNum+=1
				ad = adNum
				l=layer
				adname = ads['adname']
				offset = ads['offset']
				duration = ads['duration']
				fps = ads['fps']
				x = adX[adNum]
				y = adY[adNum]
				width = adWidth[adNum]
				height = adHeight[adNum]
				sleep(0.1)
				if adNum != 0 and overlap[adNum]==false 
					while i != 0
					end
				else
					sleepDur = offset-sleepDur
					sleep(sleepDur)
					sleepDur=offset
				end

				Concurrent::Promise.execute do
					if i==0
						socket.write("play 1-1 #{asset["filename"]} SEEK #{offset * fps} auto"+"\r\n")
						response = response+socket.gets
					end
					i+=1
					puts "Started sending for: #{adname}"
					socket.write("MIXER 1-2 CHROMA blue 0 0.1"+"\r\n")
					socket.write("mixer 1-#{l} fill #{x} #{y} #{width} #{height}"+"\r\n")		
					socket.write("play 1-#{l} #{adname}"+"\r\n")
				    response = response+socket.gets		  
				    sleep(duration)
					socket.write("CLEAR 1-#{l}"+"\r\n")
					response = response+socket.gets
					puts "completed sending for: #{adname}"	
					i-=1
					numofAds-=1
				end

				layer+=1
				
			end

			while numofAds !=0 do
			end
			socket.close
			socket = TCPSocket.new(host,port) 
			socket.write("MIXER 1 CLEAR"+"\r\n")
			socket.write("CLEAR 1"+"\r\n")
			socket.write("REMOVE 1 FILE"+"\r\n")
			socket.close

			if response.include? "404"
				msg = "file created may be corrupted"
				response = ""
			else
  				msg = baseURI+"videos/#{asset['filename']}_pre.mov"
				response = ""
			end
			result.merge!({"#{asset['filename']}" => msg })
		end
		puts result.to_json
		render json: result.to_json, status: :ok
	end

	def htmlPreview(json1)
		require 'socket'
		require 'open-uri'
		require 'etc'
		require 'rmagick'
		require 'json'

		htmldirectory = "#{Etc.getpwuid.dir}"+'/htmlpreview/'
		result =Array.new
		puts "json: #{json1}"
		i = 0
		json1.each do |asset|
			
			videoName = File.basename(asset['Video'],File.extname(asset['Video']))
			extension = File.extname(asset['Video'])
			duration  = asset['Duration']
			offset    = asset['Offset']
			filepath  = File.basename(asset['GraphicsPath']),File.extname(asset['GraphicsPath'])
			fileextension = File.extname(asset['GraphicsPath'])
		
 				if !fileextension.include? ".zip"
					File.write htmldirectory + filepath+fileextension, open(asset['GraphicsPath']).read
					if fileextension == ".tga"
						image = htmldirectory + filepath + fileextension
						img = Magick::Image.read(image).first
						ofile = image.sub ".tga",".png"
						img.write(ofile)
						FileUtils.rm(image)
						output = `convert #{ofile} -alpha extract png:- | convert - -threshold 65534 -format %@ -write info: alpha.png`
						x_coordinate = output.partition('+').last.partition('+').first
						y_coordinate = output.partition('+').last.partition('+').last
					end
				else
					extractFolder = htmldirectory + 'tga.zip'
					content = open(asset['GraphicsPath'])
					
					open(extractFolder, 'wb') do |fo|
					  fo.print open(asset['GraphicsPath']).read
					end

					FileUtils::mkdir_p htmldirectory + "ExtractedFiles/"
					destination = htmldirectory + "ExtractedFiles"
					file = extractFolder

					Zip::File.open(file) do |zip_file|
					    zip_file.each do |f|
					      fpath = File.join(destination, f.name)
					      zip_file.extract(f, fpath) unless File.exist?(fpath)
					    end
					end

					tga_source = destination +"/tga"

					images = Array.new() 
					images = Dir["#{tga_source}/*.tga"]
					images.sort!
					
					images.each do |image|
						img = Magick::Image.read(image).first
						ofile = image.sub ".tga",".png"
						img.write(ofile)
					end
					
					images = Array.new()
					images = Dir["#{tga_source}/*.png"]
					images.sort!

					images.each do |image|
						output1 = `convert #{image} -alpha extract png:- | convert - -threshold 65534 -format %@ -write info: alpha.png`	
						x_coordinate = output1.partition('+').last.partition('+').first
						y_coordinate = output1.partition('+').last.partition('+').last
						height1 = output1.partition('+').first
						height =  height1.partition('x').first
						width =   height1.partition('x').last
						puts "h: #{height1} height: #{height}, width: #{width}"
						if height.to_i <= 1 and width.to_i <= 1
							FileUtils.rm(image)
						end
					end
					#`convert -delay 4 -alpha set -dispose 2 -loop 0 -resize 1920x1080 #{tga_source}/*.tga "public/videos/Output#{i}.gif"`
					result << {Video: asset['Video'],Duration: asset['Duration'],Offset: asset['Offset'], X: x_coordinate.to_i, Y: y_coordinate.to_i, GraphicsPath: "http://10.0.12.197:3000/videos/21.png",display: "false"}
				end
				i+=1
		end
		render json: result.to_json
	end
end