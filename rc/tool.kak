declare-option -hidden int tool_current_error_line
declare-option -docstring 'the regex to capture the file position to jump to' \
    regex tool_jump_regex

define-command -params .. \
    -docstring %{tool [<arguments>]: make utility wrapper
All the optional arguments are forwarded to the make utility} \
    tool %{ evaluate-commands %sh{
     tool_name=${1}
     shift
     output=$(mktemp -d "${TMPDIR:-/tmp}"/kak-${tool_name}.XXXXXXXX)/fifo
     mkfifo ${output}
     ( eval "$@" > ${output} 2>&1 ) > /dev/null 2>&1 < /dev/null &

     printf %s\\n "evaluate-commands -try-client '$kak_opt_toolsclient' %{
               edit! -fifo ${output} -scroll *${tool_name}*
               set-option buffer filetype tool:${tool_name}
               set-option buffer tool_current_error_line 0
               hook -always -once buffer BufCloseFifo .* %{ nop %sh{ rm -r $(dirname ${output}) } }
           }"
}}

set-face global ToolPath string
set-face global ToolLine value
set-face global ToolColumn value
set-face global ToolSuccess green+b
set-face global ToolFail red+b
add-highlighter shared/tool group
add-highlighter shared/tool/ line '%opt{tool_current_error_line}' default+b

hook -group make-highlight global WinSetOption filetype=tool:(.*) %{
    add-highlighter window/tool ref tool
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/tool }
    evaluate-commands %sh{
        tool_name=${kak_hook_param_capture_1}
        highlight_group_opt=tool_${tool_name}_highlight_group
        echo "add-highlighter window/tool_${tool_name} ref %opt{${highlight_group_opt}}"
        echo "hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/tool_${tool_name} }"
    }
}

hook global WinSetOption filetype=tool:(.*) %{
    hook buffer -group tool-hooks NormalKey <ret> "tool-jump %val{hook_param_capture_1}"
    hook -once -always window WinSetOption filetype=.* %{ remove-hooks buffer tool-hooks }
}

define-command -hidden tool-open-error -params 4 %{
    evaluate-commands -try-client %opt{jumpclient} %{
        edit -existing "%arg{1}" %arg{2} %arg{3}
        echo -markup "{Information}%arg{4}"
        try %{ focus }
    }
}

define-command -hidden tool-jump -params 1 %{
        set-option buffer make_current_error_line %val{cursor_line}
        evaluate-commands %sh{ echo tool-$1-jump }
}

define-command tool-next-error -docstring 'Jump to the next tool error' -params 1 %{
    evaluate-commands -try-client %opt{jumpclient} %{
        buffer '*%arg{1}*'
        execute-keys "%opt{tool_current_error_line}ggl" "/%opt{tool_jump_regex}<ret>"
        tool-jump %arg{1}
    }
    try %{ evaluate-commands -client %opt{toolsclient} %{ execute-keys %opt{make_current_error_line}g } }
}

define-command tool-previous-error -docstring 'Jump to the previous tool error' -params 1 %{
    evaluate-commands -try-client %opt{jumpclient} %{
        buffer '*%arg{1}*'
        execute-keys "%opt{tool_current_error_line}g" "<a-/>{tool_jump_regex}<ret>"
        tool-jump %arg{1}
    }
    try %{ evaluate-commands -client %opt{toolsclient} %{ execute-keys %opt{make_current_error_line}g } }
}
