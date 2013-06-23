#encoding: utf-8
require 'json'
require 'sass'
require 'sinatra/base'
require 'sinatra/content_for'
require 'sinatra/reloader'
require 'micro-optparse'
require 'RMagick'
require 'colormath'

require './helpers/boxhelper'

module Box
	class App < Sinatra::Base
		helpers Sinatra::ContentFor
		helpers Sinatra::BoxHelper

		configure :development do
      enable :logging
      enable :dump_errors
      register Sinatra::Reloader
    end

		get '/' do 
			session[:shadow] = nil
			session[:width] = nil 
			session[:height] = nil
			session[:pixel_spacing] = nil
			erb :index
		end

		post '/' do 

			@pixel_size = params[:pixel_size].to_i || 5
			@blur = params[:blur].to_i || 0
			@pixel_spacing = params[:pixel_spacing].to_i || 2


			tmpfile = params[:photo][:tempfile]
			image = Magick::ImageList.new
			bin = File.open(tmpfile, 'r'){ |file| file.read }
			img = image.from_blob(bin)
			
			width     = img.columns
			height    = img.rows

			
			shadows = []
			pixel_size      = @pixel_size
			w_pixels        = width/pixel_size
			h_pixels        = height/pixel_size

			pixels = []
			w_pixels.times do |w|
				h_pixels.times do |h|
					x = w*pixel_size
    			y = h*pixel_size

    			group = img.get_pixels(x, y, pixel_size, pixel_size)

    			blended_pixel = group.inject do |val, p| 
    				c = ColorMath::RGB.new(p.red.to_f/255, p.green.to_f/255, p.blue.to_f/255) 
			      result = (val.class.name == "Magick::Pixel") ? c : ColorMath::Blend.alpha(val, c, 0.5) 
			      result
    			end


    			if (blended_pixel.class.name == "Magick::Pixel")
    				shadows << "#{x}px #{y}px #{@blur}px rgb(#{blended_pixel.red},#{blended_pixel.green},#{blended_pixel.blue})"
    			else
    				shadows << "#{x}px #{y}px #{@blur}px #{blended_pixel.hex}"
    			end

				end
			end

			pixel_spacing   = (@pixel_spacing < 0 or @pixel_size > pixel_size) ? pixel_size : @pixel_spacing
		
			session[:shadow] = shadows
			session[:width] = width 
			session[:height] = height
			session[:pixel_spacing] = pixel_spacing
			erb :index
		end

		get '/stylesheet/:name.css' do
      content_type 'text/css', :charset => 'utf-8'
      scss :"stylesheet/#{params[:name]}"
    end


	end
end