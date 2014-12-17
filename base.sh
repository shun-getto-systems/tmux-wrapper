# usage
#
# . base.sh
#
# tmux_wrapper_session=myhost
# tmux_wrapper_color=cyan
# tmux_wrapper_host=192.168.1.1
#
# tmux_wrapper_path(){
#	  # bind key, name, path
#	  echo C name /path/to/dir
# }
#
# tmux_wrapper_main


# suppported options and defaults
#
# tmux_wrapper_session : name of tmux session      ; Session
# tmux_wrapper_file    : specify base .tmux.conf   ; ~/.tmux.conf
# tmux_wrapper_color   : specify status color      ; cyan
# tmux_wrapper_term    : screen or screen-256color ; screen-256color
# tmux_wrapper_host    : ssh remote host           ; localhost
# tmux_wrapper_path()  : when call, echo list of remote host's dir and bind key
#
# tmux_wrapper_work    : working file use in script ; ~/.tmux.wrapper.conf
# tmux_wrapper_socket  : tmux socket path           ; ~/.tmux.wrapper.sock

tmux_wrapper_main(){
	if [ -z "$tmux_wrapper_work" ]; then
		tmux_wrapper_work=~/.tmux.wrapper.conf
	fi
	if [ -z "$tmux_wrapper_file" ]; then
		tmux_wrapper_file=~/.tmux.conf
	fi
	if [ -z "$tmux_wrapper_socket" ]; then
		tmux_wrapper_socket=~/.tmux.wrapper.sock
	fi
	if [ -z "$tmux_wrapper_color" ]; then
		tmux_wrapper_color=cyan
	fi
	if [ -z "$tmux_wrapper_term" ]; then
		tmux_wrapper_term=screen-256color
	fi
	if [ -z "$tmux_wrapper_host" ]; then
		tmux_wrapper_host=localhost
	fi

	if [ -z "$tmux_wrapper_session" ]; then
		tmux_wrapper_session=Session
	fi
	tmux_wrapper_session="[$tmux_wrapper_session]"

	cp "$tmux_wrapper_file" "$tmux_wrapper_work"
	echo >> "$tmux_wrapper_work"
	echo "# generated by hosts/base.sh" >> "$tmux_wrapper_work"
	echo >> "$tmux_wrapper_work"
	echo 'set -g default-terminal "'$tmux_wrapper_term'"' >> "$tmux_wrapper_work"
	echo 'set -g status-left "#[fg='$tmux_wrapper_color']#S"' >> "$tmux_wrapper_work"
	echo 'set -g status-right "#[fg='$tmux_wrapper_color'][#(ssh '$tmux_wrapper_host' uptime | sed '"'s/.*load average: //'"')]"' >> "$tmux_wrapper_work"

	tmux_wrapper_path | awk '{print "bind " $1 " neww -n " $2 " \"ssh '$tmux_wrapper_host' -t '"'"'cd " $3 "; bash'"'"'\""}' >> "$tmux_wrapper_work"

	tmux_wrapper_exec
}
tmux_wrapper_exec(){
	if tmux -S "$tmux_wrapper_socket" has -t "$tmux_wrapper_session" 2> /dev/null; then
		tmux -S "$tmux_wrapper_socket" a -t "$tmux_wrapper_session"
		return
	fi

	tmux_wrapper_window_name=$(tmux_wrapper_path | head -1 | awk '{print $2}')
	tmux_wrapper_window_dir=$(tmux_wrapper_path | head -1 | awk '{print $3}')
	if [ -z "$tmux_wrapper_window_name" ]; then
		tmux_wrapper_exec_bare
		return
	fi
	if [ -z "$tmux_wrapper_window_dir" ]; then
		tmux_wrapper_exec_bare
		return
	fi

	tmux -S "$tmux_wrapper_socket" -f "$tmux_wrapper_work" new -s "$tmux_wrapper_session" -n "$tmux_wrapper_window_name" "ssh $tmux_wrapper_host -t 'cd $tmux_wrapper_window_dir; bash'"
}
tmux_wrapper_exec_bare(){
	tmux -S "$tmux_wrapper_socket" -f "$tmux_wrapper_work" new -s "$tmux_wrapper_session" -n "$tmux_wrapper_session" "ssh $tmux_wrapper_host"
}

tmux_wrapper_path(){
	: # echo c name /path/to/dir # bind key, name, path
}

