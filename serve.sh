# bash serve.sh a 1234

declare -A types=(
    ['css']='text/css'
    ['html']='text/html'
    ['ico']='image/x-icon'
    ['js']='application/javascript'
)

preparea() {
    folder=$1
    port=$2
    read line
    line=($line)
    file=${line[1]}
    file="${file//%20/ }"
    type=${types[${file##*.}]}
    if [[ $file != '/'* || ! $type ]]; then
        file='/x.html'
        type='text/html'
    fi
    echo $'HTTP/1.\ncontent-type:'$type$'\n\n'"$(tr -d '\0' < "$folder$file")"
}

prepareb() {
    folder=$1
    port=$2
    while read line; do
        if [[ $line = 'GET /'* ]]; then
            line=($line)
            file=${line[1]}
            file="${file//%20/ }"
            type=${types[${file##*.}]}
            if [[ ! $type ]]; then
                file='/x.html'
                type='text/html'
            fi
            : $(echo $'HTTP/1.\ncontent-type:'$type$'\n\n'"$(tr -d '\0' < "$folder$file")" | netcat -l -w 0 $port)
        fi
    done
}

serve() {
    folder=${1:-a}
    port=${2:-1234}
    if test "$(type -t socat)"; then
        echo 'localhost:'$port
        : $(socat tcp-l:$port,fork,reuseaddr exec:"$SHELL ${BASH_SOURCE[0]} \'$folder\' $port a" 2>&1)
    elif test "$(type -t netcat)"; then
        echo 'localhost:'$port
        netcat -6 -k -l -w 1 $port | $SHELL ${BASH_SOURCE[0]} "$folder" $port b
    else
        echo 'no'
    fi
}

case $3 in
    (a) preparea "${@}" ;;
    (b) prepareb "${@}" ;;
    (*) serve "${@}" ;;
esac