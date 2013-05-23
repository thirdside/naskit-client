require 'json'
require 'open3'

module Naskit
  class Converter
    class ConvertError < RuntimeError; end

    class Profile
      def initialize(infile, outfile)
        @infile = Shellwords.escape infile
        @outfile = Shellwords.escape outfile
      end

      def matches?
        false
      end

      def file_infos
        if @infos.nil?
          o, e, s = Open3.capture3("avprobe -show_streams -of json #{@infile}")
          if s.success?
            @infos = JSON(o)
          else
            raise ConvertError, e
          end
        end
        @infos
      end

      def convert!
        _, e, s = Open3.capture3(command)
        s.success?
      end
    end

    class M4V < Profile
      def extension
        'm4v'
      end

      def match?
        audio_codec == :copy && video_codec == :copy
      end

      def command
        "avconv -i #{@infile} -c:a #{audio_codec} -c:v #{video_codec} #{@outfile}.#{extension}"
      end

      def audio_codec
        :copy
      end

      def video_codec
        current_codec = file_infos["streams"].detect{|s| s["codec_type"] == "video"}["codec_name"] rescue nil
        current_codec == "h264" ? :copy : :libx264
      end
    end
  end
end