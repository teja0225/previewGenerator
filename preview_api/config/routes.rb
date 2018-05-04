Rails.application.routes.draw do
	get "/show_preview/:videoName" => "preview#show_preview"
	post "/" => "preview#index"
end