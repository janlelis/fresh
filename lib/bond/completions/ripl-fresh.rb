# no advanced auto completion, yet
# todo: not only default options

require 'readline'

file_completion = proc{ |input|
  ::Readline::FILENAME_COMPLETION_PROC.call(input) || []
}

system_command_completion = proc{ Ripl.config[:fresh_system_words] }

everything_completion = proc{ # TODO: improve
  file_completion.call +
  system_command_completion.call + 
  Kernel.instance_methods +
  Object.instance_methods +
  Object.constants
}


complete :on => Ripl.config[:fresh_match_regexp],
         :search => false,
          &file_completion

# TODO fires only when space after ^
complete :on => Ripl::Fresh.option_array_to_regexp( Ripl.config[:fresh_system_prefix] ),
#         :search => false,
          &system_command_completion

complete :on => /^[a-z\/_-]+/i,
          &everything_completion
# J-_-L
