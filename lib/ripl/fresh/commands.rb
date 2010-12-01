require 'ripl'
require 'fileutils'

module Ripl
  module Fresh
    module Commands
=begin
      def ls(path='.')
        Dir[ File.join( path, '*' )].map{|res| res =~ /^#{path}\/?/; $' }
      end
      alias dir ls
=end

      def cd( path = File.expand_path('~') )
        new_last_path = FileUtils.pwd
        if path == '-'
          if @last_path
            path = @last_path
          else
            warn 'Sorry, there is no previous directory.'
            return
          end
        end
        FileUtils.cd path
        @last_path = new_last_path
        nil
      end
    end
  end
end

Ripl::Commands.send :include, Ripl::Fresh::Commands if defined? Ripl::Commands

# J-_-L
