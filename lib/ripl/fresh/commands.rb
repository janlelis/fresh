require 'ripl'
require 'fileutils'

module Ripl
  module Fresh
    module Commands
      def cd( path = File.expand_path('~') )
        new_last_path = FileUtils.pwd
        if path =~ /^\.{3,}$/
          path = File.join( %w[..] * ($&.size-1) )
        elsif path == '-'
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
