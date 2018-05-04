# previewGenerator

Objective: To develop a Preview for our Cloud Port Interface where the user can get to see the preview of those particular portions of the video where some secondaries need to be played on the top of the primary video.
(We are only concerned with displaying those Particular Portions)

There are basically two Approaches that have been considered here for Generating the Preview:

1. The HTML Preview Approach
2. The Casper CG Approach

*** The HTML Preview Approach

	This approach makes use of the Languages HTML,Javascript and CSS.
	Here VideoJS is used in the HTML.

	The HTML reads data from a JSON File and plays the Graphics on the Video accordingly.
	The Graphics will be played only for the Specified Duration of Time.
	Once a Graphics has finished Playing, the Video will be seeked to the Next Position where the Graphics will be Played.

	This approach makes use of an API which is written in Ruby.

	In this Approach, we give Input to an API in the form of JSON that includes Parameters like:

		* Link of the TGA Files
		* Link of the Video
		* Duration of the Graphics
		* Offset of the Video at which the Graphics has to be Played.

	The API will return an Output which is also in the form of a JSON that will have Parameters like:	

		* Link of the Grpahics that is to be Played (Can be Animated GIF Format or PNG Format)
		* Link of the Video
		* Duration of the Graphics
		* Offset of the Video at which the Graphics has to be Played.
		* X Coordinate 
		* Y Coordinate

	Installation:
	
	Install Ruby 2.3.1				(https://www.ruby-lang.org/en/documentation/installation/)
	Install Rails Server 5.0.1		(https://gorails.com/setup/ubuntu/16.04)

	Examples:

	Input to the API

	[{"option":"html"},{
	"Video":"http://media.w3.org/2010/05/sintel/trailer.mp4",
	"Duration":"40",
	"Offset":"20",
	"GraphicsPath":"http://10.0.12.119:8004/tga.zip"
	},{
	"Video":"http://media.w3.org/2010/05/sintel/trailer1.mp4",
	"Duration":"40",
	"Offset":"20",
	"GraphicsPath":"http://10.0.12.119:8004/tga.zip"
	}]

	Option: 	  Gives the User the Choice to Tweak Between the HTML and the CasperCG Approach.
	Video : 	  Source of the Video File.
	Duration:	  Duration for which the Graphics has to be Played.
	Offset:		  Offset at which the Graphics will be Played.
	GraphicsPath: The Path that Points to the Zip Folder.

	Output from the API

   [
   {
       "Video": "http://media.w3.org/2010/05/sintel/trailer.mp4",
       "Duration": "40",
       "Offset": "20",
       "X": "1",
       "Y": "1",
       "GraphicsPath": "/home/arunava/preview/ExtractedFiles/tga/Output.gif"
   },
   {
       "Video": "http://media.w3.org/2010/05/sintel/trailer1.mp4",
       "Duration": "40",
       "Offset": "20",
       "X": "1",
       "Y": "1",
       "GraphicsPath": "/home/arunava/preview/ExtractedFiles/tga/Output.gif"
   }
   ]

	Video : 	   Source of the Video File.
	Duration:	   Duration for which the Graphics has to be Played.
	Offset:		   Offset at which the Graphics will be Played.
	X:			   X Coordinate of the Screen at which the Graphics should appear on the Video
	Y:			   Y Coordinate of the Screen at which the Graphics should appear on the Video
	GraphicsPath:  The Path that Points to the Graphics which is to be Played.

	Usage:

	* Run the rails server which has API.
	* Use POST request with json consisting of videoname to play and all the graphics to played on it along with offset(from  where to begin to play in seconds) duration(time duration to play the ad in seconds)
	* Give the path from where the assets(Video and Graphics) must be downloaded from.
	* Mention the zip path.(Can be an HTTP Request)
	* POST request's response consists of {Link of the Graphics that is to be Played, Link of the Video, Duration of the Graphics, Offset of the Video at which the Graphics has to be Played, X Coordinate, Y Coordinate}
	* Use GET request by sending the video name for which you are interested to watch the preview of. The response renders a html page which will play the Preview.

	Working: 

	* User invokes the API sending the JSON with above mentioned details
	* API wil parse the JSON and download all the assets required to generated the preview from the path mentioned in the JSON.
	* The tga's given are unpacked and converted in a required form, here it is converted to a video playable on HTML Page. Height and Width of the tga's is fetched and respective proportion is chosen to play ad upon the primary video.
	* Using the offset and duration mentioned in the JSON, the ads which will overlap with other ads is known.
	* Care is taken that transparent images do not show blue or green colour behind it representing trasparency.(By Removing those TGA's that have height and width less tahn 1 Pixel)
	* The Json then includes the Required Parameters which are parsed by the HTML and the Video is Played accordingly with the Required Graphics on it.


*** The Casper CG Approach

	The rails API built uses CasparCG Server which is used for broadcasting content. The assets mentioned are loaded and according to the offset and duration mentioned, the ads are played on the primary video. Here instead of actually broadcasting it, it is written to a disk storage which can then be used to give current working preview of the primary video. The assets could also be present on different server, by giving the path to access the assets, the assets are first downloaded and later the preview is generated.

	Installation:

	* Ruby version - 2.3.1 , rails (https://gorails.com/setup/ubuntu/14.04)

	* CasparCGServer beta 1 - get preview.zip folder, and extract it. open terminal go to preview path and execute ./run.sh This will install correct version of CasparCGServer required and also makes the necessary changes in configuration. Now you can go to CasparCGServer folder and execute ./run.sh to run the CasparCGServer.
	run.sh has the script to execute in order to download CasparCGServer of required version and make changes in the configuration as per the requirements.

	run.sh:

		wget "https://sourceforge.net/projects/casparcg/files/CasparCG_Server/CasparCG%20Server%202.1.0%20Beta%201%20for%20Linux.tar.gz/download"
		if [ "$?" -eq 0 ]; then
			tar -zxvf download
			rm -rf download
			mkdir CasparCGServer
			mv -T CasparCG\ Server CasparCGServer
			cp casparcg.config CasparCGServer
		else
			printf "error dowloading file\n"
		fi

	Usage:

	* Run CasparCGServer and rails server which has API.
	* Use POST request with json consisting of videoname to play and all the ads to played on it along with offset(from where to begin to play in seconds) duration(time duration to play the ad in seconds) fps(frames per second, rate at which the ad must be played) 
	* Give the path from where the assets(video and ads) must be downloaded from.
	* Mention the zip path it the ad is a sequence of images.
	* POST request's response consists of video name and the path where you can find the preview video.

	* Example JSON POST request
		INPUT:

		[
		{"option":"CasparCG"},
		{"filename":"http://yourDomain.com/yourfolder/folder/video.extension",
		"ad":
		[
		{"adname" : "http://yourDomain.com/yourfolder/folder/imageSequences.zip","offset":2,"duration":10 , "fps" : 25},
		{"adname" : "http://yourDomain.com/yourfolder/folder/image1.extension","offset":4,"duration":5 , "fps" : 25},
		{"adname" : "http://yourDomain.com/yourfolder/folder/image2.extension","offset":15,"duration":2 , "fps" : 25}
		]
		}
		]

		*option: specify which approach must be used to show preview.
		*filename: specify the video name you want to generate preview for.
		*ad: mention sequence of ads that you want to play on video.
		*adname: specify path for either a single image which will be played as ad or a sequence of images which will be converted into required form and played on video.
		*offset: specity the time at which the ad should begin to play relative to video in seconds.
		*duration: specity the amount of time for which the ad must play in seconds.
		*fps: give the frame rate at which the ad must be played.

		OUTPUT:
		{
    	"http://yourDomain.com/yourfolder/folder/video.extension" : "http://domain.com/preview/CasparCGServer/media/"video_pre.mov"
		}

		*key: the name of the video
		*value: path for the pre-generated preview

	* Use GET request by sending the video name for which you are interested to watch the preview of. The response renders a html page which will play the pre generated preview.
	* Example for get request
		http://DomainWhereRailsIsRunning.com/videoname_for_which_you_want_to_see_preview
	* As a response the API renders a view where you can play your preview.
		
	Working: 

	* User invokes the API sending the JSON with above mentioned details
	* API wil parse the JSON and download all the assets required to generated the preview from the path mentioned in the JSON.
	* The tga's given are unpacked and converted in a required form, here it is converted to a video playable on casparCGServer. Height and Width of the tga's is fetched and respective proportion is chosen to play ad upon the primary video.
	* Using the offset and duration mentioned in the JSON, the ads which will overlap with other ads is known.
	* Finally by making a connection to CasarCGServer, commands are sent according to the offset and duration values.
	* Care is taken that transparent images do not show blue or green colour behind it representing trasparency.
	* The generated video is not shown on screen rather a command is issued to add the video preview to disk.
	* If there are no errors in generating the preview, path for the video generated is passed, else an error message is sent in the JSON response.
	* While a user wants to see the preview he can invoke the serevr with videoname, HTML page is rendered where the user can play the video.
