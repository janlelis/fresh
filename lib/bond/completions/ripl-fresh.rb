# no advanced auto completion, yet
# only do some file completion - because it's the most important completion ;)

require 'readline'

file_completion = proc{ |input|
  ::Readline::FILENAME_COMPLETION_PROC.call(input) || []
}

complete :on => Ripl.config[:fresh_system_regexp],
         :search=>false,
          &file_completion

# TODO fires only when space after ^
complete :on => Ripl::Fresh.option_array_to_regexp( Ripl.config[:fresh_system_prefix] ),
         :search=>false,
          &file_completion
