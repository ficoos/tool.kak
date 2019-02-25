declare-option -docstring 'shell command to run to run nosetests' \
    str nosecmd "nosetests"

define-command nose -params .. \
    -docstring %{nose [<arguments]: nosetests utility wrapper
All the optional arguents are passed to the nose utility} %{
    tool "nose" %opt{nosecmd} %arg{@}
}

declare-option -hidden str tool_nose_highlight_group "nose"
add-highlighter shared/nose group
add-highlighter shared/nose/ regex '^\h+File\h+(?<file>".*?"),\h+line\h+(?<line>\d+),\h+in\h+(?<function>.*?)\n' 1:ToolPath 2:ToolLine 3:function
add-highlighter shared/nose/ regex '^(FAIL:)\h+.*?\n' 1:ToolFail
add-highlighter shared/nose/ regex '^\h*OK\h*\n' 0:ToolSuccess
add-highlighter shared/nose/ regex '^\h*(FAILED)\h*\(failures=(\d+)\)\n' 1:ToolFail 2:value
add-highlighter shared/nose/ regex '^[-=]+\n' 0:white

define-command -hidden tool-nose-jump %{
            execute-keys <a-h><a-l> s '^\h+File\h+"(.*?)",\h+line\h+(\d+), in .*\z' <ret>l
            tool-open-error %reg{1} %reg{2} 0 ""
}
