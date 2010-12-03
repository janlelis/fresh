require 'ripl'
require 'fileutils'

module Ripl
  module Fresh
    VERSION = '0.2.0'

    def before_loop
      @command_mode = :ruby
      @real_buffer  = nil
      super
      # register bond completion
      Ripl.config[:completion][:gems] ||= []
      Ripl.config[:completion][:gems] << 'ripl-fresh'
    end

    # determine @command_mode
    def get_input
      command_line = super

      # This case statement decides the command mode,
      #  and which part of the input should be used for what...
      #  Note: Regexp match groups are used!
      @result_storage = @result_operator = nil

      @command_mode = case command_line
      # force ruby with a space
      when /^ /
        :ruby
      # regexp match shell commands
      when *Array( Ripl.config[:fresh_patterns] ).compact
        command_line     = $~[:command_line]     if $~.names.include? 'command_line'
        command          = $~[:command]          if $~.names.include? 'command'
        @result_operator = $~[:result_operator]  if $~.names.include? 'result_operator'
        @result_storage  = $~[:result_storage]   if $~.names.include? 'result_storage'
        forced           = !! $~[:force]         if $~.names.include? 'force'

        if forced
          :system
        elsif Ripl.config[:fresh_ruby_commands].include?( command )
          :ruby
        elsif Ripl.config[:fresh_mixed_commands].include?( command )
          :mixed
        elsif Ripl.config[:fresh_system_commands].include?( command )
          :system
        elsif Kernel.respond_to? command.to_sym
          :ruby
        else
          Ripl.config[:fresh_unknown_command_mode]
        end
      else
        Ripl.config[:fresh_default_mode]
      end

      command_line
    end

    # get result (depending on @command_mode)
    def loop_eval(input)
      if input == ''
        @command_mode = :system and return
      end

      case @command_mode
      when :system # generate ruby code to execute the command
        if !@result_storage
          ruby_command_code = "_ = system '#{ input }'\n"
        else
          temp_file = "/tmp/ripl-fresh_#{ rand 12345678901234567890 }"
          ruby_command_code = "_ = system '#{ input } 2>&1', :out => '#{ temp_file }'\n"
          
          # assign result to result storage variable
          case @result_operator
          when '=>', '=>>'
            result_literal   = "[]"
            formatted_result = "File.read('#{ temp_file }').split($/)"
            operator = @result_operator == '=>>' ? '+=' : '='
          when '~>', '~>>'
            result_literal = "''"
            formatted_result = "File.read('#{ temp_file }')"
            operator = @result_operator == '~>>' ? '<<' : '='
          end
          ruby_command_code << %Q%
            #{ @result_storage } ||= #{ result_literal }
            #{ @result_storage } #{ operator } #{ formatted_result }
            FileUtils.rm '#{ temp_file }'
          %
        end

        # ruby_command_code << "raise( SystemCallError.new $?.exitstatus ) if !_\n" # easy auto indent
        ruby_command_code << "if !_
                                raise( SystemCallError.new $?.exitstatus )
                              end;"
        
        super @input = ruby_command_code

      when :mixed # call the ruby method, but with shell style arguments TODO more shell like (e.g. "")
        method_name, *args = *input.split
        super @input = "#{ method_name }(*#{ args })"

      else # good old :ruby
        super
      end
    end

    # system commands don't have output values and Ruby is displayed normally
    def print_result(result)
      if @error_raised ||
           @command_mode == :system ||
           @command_mode == :mixed && (!result || result == '')
        # don't display anything
      else
        super # puts(format_result(result))
      end
    end
  end
end

# load plugins and hook in (and work around readline loading behaviour)
Ripl.config[:readline] = false
require 'ripl/readline'
require 'ripl/multi_line'
Ripl::Shell.send :include, Ripl::Fresh

# load :mixed commands
require File.dirname(__FILE__) + '/fresh/commands'

# fresh config
require File.dirname(__FILE__) + '/fresh/config'

# fresh_prompt management
require File.dirname(__FILE__) + '/fresh/prompt'

# J-_-L
