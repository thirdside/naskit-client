#encoding: UTF-8
require "naskit/version"

require 'cgi'
require 'fileutils'
require 'net/http'
require 'open3'
require 'json'

require_relative 'naskit/converter'

module Naskit

  DEFAULT_EXTENSIONS  = %w( avi mp4 mkv m4v )
  DEFAULT_FORMAT      = "%show/%season/%number. %title"

  class Logger
    class << self
      attr_accessor :verbose
    end

    def self.log message
      $stdout.puts message if verbose
    end

    def self.err message
      $stderr.puts message if verbose
    end
  end

  class Episode

    attr_accessor :id, :number, :title, :description, :season, :show, :date

    def self.parse(data)
      e = Episode.new

      %w(id number title description season show).each do |attr|
        e.send("#{attr}=", data[attr])
      end

      e
    end
  end

  class API

    def self.get(file)
      [AtomicParsley, WWW].each do |klass|
        if e = klass.get(file)
          return e
        end
      end
      nil
    end

    class AtomicParsley

      @@prop = {
        "©nam" => 'title',
        "©dat" => 'date',
        "tvsh" => 'show',
        "tvsn" => 'season',
        "tven" => 'number',
        "desc" => 'description',
        "stik" => 'type'
      }

      def self.get(file)
        info = {}

        _, stdout, _ = Open3.popen3('AtomicParsley', file, '-t')
        parsed = (stdout.gets(nil) || "").scan  /Atom "(.\w+)"\scontains:\s(.+)/
        parsed.each do |name, value|
          info[@@prop[name]] = value if @@prop[name]
        end

        if info['show'] && info['season'] && info['number'] && info['title']
          Episode.parse(info)
        else
          Logger.err "Naskit::API::AtomicParsley Can't collect enough information for #{file}"
        end
      end
    end

    class WWW

      @@url = "http://naskit.thirdside.ca"

      def self.get(file)
        fetch("#{@@url}/search/?q=#{CGI.escape(File.basename(file))}")
      end

      protected

      def self.fetch(url)
        request = Net::HTTP::Get.new(url)
        request['Accept'] = "application/json"

        uri = URI.parse url
        response = Net::HTTP.start(uri.host, uri.port) {|http|
          http.request(request)
        }

        case response
          when Net::HTTPSuccess then
            Episode.parse(JSON.parse(response.body))
          when Net::HTTPRedirection then
            fetch(response['location'])
          else
            Logger.err "Naskit::API::WWW Can't find episode with #{url}"

            nil
        end
      end
    end
  end

  class App

    def initialize(params)
      @options = params
    end

    def run
      if failed_destination = @options[:move_failed]
        FileUtils.mkpath(failed_destination)
      end

      files.each do |file|
        if episode = API.get(file)
          copy(file, episode)
        else
          Logger.err "Naskit::App Can't find episode : #{file}"
          if failed_destination
            FileUtils.move(file, failed_destination)
            Logger.log "Naskit::App Moving failed file #{file} to #{failed_destination}"
          end
        end
      end
    end

    def files
      @files ||= Dir.glob("#{@options[:source]}/**/*.{#{@options[:extensions].join(",")}}")
    end

    def copy file, episode_name
      dest = "#{@options[:destination]}/" << converted_name(episode_name, @options[:format])

      # create directories, if they do not exist
      FileUtils.mkpath(File.dirname(dest))

      # link the file
      begin
        if @options[:convert]
          profile = Naskit::Converter::M4V.new(file, dest)

          if profile.match?
            FileUtils.link(file, dest + ".#{profile.extension}")
          else
            success = profile.convert!
            Logger.err "File not converted: #{file}" unless success
          end
        else
          FileUtils.link(file, dest + File.extname(original_file))
        end
      rescue Errno::EEXIST
        Logger.err "Naskit::App Destination file already exists : #{dest}"
      end

      # delete the original file if required
      if @options[:delete]
        FileUtils.remove(file) 
        Logger.log "Naskit::App Removing file : #{file}"
      end
    end

    def converted_name(episode, format)
      format.gsub(/%show|%season|%number|%title/).each do |match|
        episode.send(match[1..-1]).to_s.gsub(/\//, "-")
      end
    end

  end
end