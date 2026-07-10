# bash bundle.sh a/a.js a/y.js

base64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789$_'

parse() {
    file=$1
    imported=$2
    if [[ -e $file ]]; then
        text=$(<$file)
    else
        texts[$file]=''
        return
    fi
    while [[ $text = *$' \n'* ]]; do
        text=${text//$' \n'/$'\n'}
    done
    while [[ $text = *$'\n\n'* ]]; do
        text=${text//$'\n\n'/$'\n'}
    done
    IFS=$'\n' read -d '' -r -a lines <<< $text
    remove=false
    text=''
    for line in "${lines[@]}"; do
        if [[ ${line// /} = '//'* ]]; then
            continue
        fi
        if [[ !$remove && $line = *'/*'* && ! $line = *'//*'* ]]; then
            if [[ $line = *'*/'* ]]; then
                i=${line%%'/*'*}
                j=${line%%'*/'*}
                line=${line:0:${#i}}' '${line:${#j}+2}
            else
                i=${line%%'/*'*}
                line=${line:0:${#i}}
                remove=true
            fi
        fi
        if $remove; then
            if [[ $line = *'*/'* ]]; then
                i=${line%%'*/'*}
                line=${line:${#i}+2}
                remove=false
            else
                continue
            fi
        fi
        i=${line// /}
        if [[ ${#line} -gt 0 && ${#i} -gt 0 ]]; then
            text+=${line%' '}$'\n'
        fi
    done
    texta=$text

    resolve() {
        f=$1
        if [[ ${f:0:2} = './' ]]; then
            f=${f:2}
        fi
        if [[ ${f:0:1} != '.' && ${f:0:1} != '/' ]]; then
            split=(${file//'/'/ })
            split=${split[@]:0:${#split[@]}-1}
            i=''
            for j in $split; do
                i+=$j'/'
            done
            f=$i$f
        elif [[ $f = '../'* ]]; then
            i=0
            while [[ $f = '../'* ]]; do
                f=${f:3}
                i=$((i + 1))
            done
            split=(${file//'/'/ })
            split=${split[@]:0:${#split[@]}-i-1}
            i=''
            for j in $split; do
            	i+=$j'/'
            done
            if [[ ${#i} -gt 0 ]]; then
                f=$i$f
            fi
        fi
        if [[ ${f:${#f}-3} != '.js' ]]; then
            f+='.js'
        fi
        echo "$f"
    }

    declare -A files
    order=()
    i=${text%%$'import '*}
    i=${#i}
    [ $i = ${#text} ] && i=-1
    while [[ $i -gt -1 ]]; do
        if [[ $i -ne 0 && ${text:i-1:1} != $'\n' && ${text:i-1:1} != ' ' ]]; then
            text=${text:i+6}
            i=${text%%'import '*}
            i=${#i}
            [ $i = ${#text} ] && i=-1
            continue
        fi
        text=${text:i}
        i=6
        while [[ ${text:i:1} = ' ' ]]; do
            i=$((i + 1))
        done
        if [[ ${text:i:1} = '{' ]]; then
            text=${text:i}
            i=${text%%'}'*}
            i=${#i}
            names=${text:1:i-1}
            split=(${names//','/ })
            names=()
            for name in "${split[@]}"; do
                name=("${name// /}")
                if [[ $name != '' && $name != '{' && $name != '}' ]]; then
                    names+=("$name")
                fi
            done
            text=${text:i}
            if [[ $text = *' from '* ]]; then
                i=${text%%' from '*}
                i=$((${#i} + 6))
                while [[ ${text:i:1} = ' ' ]]; do
                    i=$((i + 1))
                done
                if [[ ${text:i:1} = "'" ]]; then
                    text=${text:i+1}
                    f=$(resolve "${text%%"'"*}")
                    if [[ ! "${!files[@]}" =~ $f ]]; then
                        files[$f]=''
                        order+=("$f")
                    fi
                    for name in "${names[@]}"; do
                        files[$f]+=$name$'\n'
                    done
                fi
            fi
        else
            names=()
            if [[ $text = *' from '* ]]; then
                j=${text%%' '*}
                j=${#j}
                k=${text%%' from '*}
                k=${#k}
                while [[ $j -lt $k ]]; do
                    while [[ ${text:i:1} = ' ' ]]; do
                        i=$((i + 1))
                    done
                    name=${text:i:k}
                    name=(${name//' '/ })
                    name=${name[0]}
                    if [[ $name != '' && $name != '{' && $name != '}' ]]; then
                        names+=("$name")
                    fi
                    i=$j
                    text=${text:j}
                    if [[ $text = *','* ]]; then
                        j=${text%%','*}
                        j=${#j}
                    fi
                    k=${text%%' from '*}
                    k=${#k}
                    [ $k = ${#text} ] && k=-1
                done
                text=${text:k}
                i=6
            fi
            while [[ ${text:i:1} = ' ' ]]; do
                i=$((i + 1))
            done
            if [[ ${text:i:1} = "'" ]]; then
                text=${text:i+1}
                i=${text%%"'"*}
                f=$(resolve "${text:0:${#i}}")
                if [[ ! "${!files[@]}" =~ $f ]]; then
                    files[$f]=''
                    order+=("$f")
                fi
                for name in "${names[@]}"; do
                    files[$f]+=$name$'\n'
                done
            fi
        fi
        i=${text%%'import '*}
        i=${#i}
        [ $i = ${#text} ] && i=-1
    done
    modules[$file]=''
    for i in "${order[@]}"; do
        modules[$file]+=$i$'\n'
    done
    for i in "${order[@]}"; do
        if [[ ! "${imported[@]}" =~ "$i" ]]; then
            if [[ ! "${!modules[@]}" =~ "$i" ]]; then
                return
            else
                mods=(${modules[$i]//$'\n'/ })
                if [[ ! "${mods[@]}" =~ "$file" ]]; then
                    return
                fi
            fi
        fi
    done
    exporta=('async' 'class' 'const' 'default' 'function' 'let' 'var')
    repeata=($'\n' ' ' '(' ',' '.' '[')
    text=$texta
    i=${text%%'export '*}
    i=${#i}
    [ $i = ${#text} ] && i=-1
    while [[ $i -gt -1 ]]; do
        text=${text:i+7}
        for name in "${exporta[@]}"; do
            i=${text%%$name*}
            i=${#i}
            [ $i = ${#text} ] && i=-1
            if [[ $i -gt -1 && $i -lt 3 ]]; then
                text=${text:i+${#name}}
            fi
        done
        if [[ $text = *$'\n'* ]]; then
            names=${text%%$'\n'*}
        fi
        split=()
        i=${names%%'='*}
        i=${#i}
        j=${names%%'('*}
        j=${#j}
        if [[ ! $names = *'='* || $names = *'('* && $i -gt $j ]]; then
            split+=("$names")
        else
            while [[ $names = *'='* ]]; do
                i=${names%%'='*}
                split+=("$i")
                i=${#i}
                names=${names:i}
                if [[ $names = *','* ]]; then
                    i=${names%%','*}
                    i=${#i}
                    names=${names:i}
                else
                    names=''
                fi
            done
        fi
        names=()
        for name in "${split[@]}"; do
            while [[ "${repeata[@]}" =~ ${name:0:1} ]]; do
                name=${name:1}
            done
            for i in "${repeata[@]}"; do
                if [[ $name = *"$i"* ]]; then
                    name=${name%%$i*}
                fi
            done
            names+=("$name")
        done
        if [[ ! "${!files[@]}" =~ $file ]]; then
            files[$file]=''
            order+=("$file")
        fi
        for name in "${names[@]}"; do
            files[$file]+=$name$'\n'
        done
        i=${text%%'export '*}
        i=${#i}
        [ $i = ${#text} ] && i=-1
    done

    replace() {
        text=$1
        past=$2
        next=$3
        a=0
        i=${#next}
        j=${#past}
        while [[ ${text:a} = *"$past"* ]]; do
            b=${text:a}
            b=${b%%$past*}
            a=$((a + ${#b}))
            if [[ ${#text} -lt $((a + j + 1)) ]]; then
                echo "$text"
                return
            fi
            cont=false
            textb=${text:a-7:7}$next
            for name in "${exporta[@]}"; do
                if [[ $textb = *"$name"'_'* ]]; then
                    cont=true
                    break
                fi
            done
            if [[ $cont = true || $base64 = *"${text:a+j:1}"* || $base64"'." = *"${text:a-1:1}"* ]]; then
                a=$((a + j))
                continue
            fi
            text=${text:0:a}$next${text:a+j}
            a=$((a + i))
        done
        echo "$text"
    }

    text=$texta
    for f in "${!files[@]}"; do
        string=$(echo -n $f | tr -c $base64 '_')
        split=(${string//'_'/ })
        split=${split[@]:${#split[@]}-1:1}
        string=${string:0:${#string}-${#split}-1}
        ref=(${files[$f]//$'\n'/ })
        for name in "${ref[@]}"; do
            text=$(replace "$text" "$name" "$name"'_'"$string")
        done
    done
    IFS=$'\n' read -d '' -r -a lines <<< $text
    text=''
    for line in "${lines[@]}"; do
        if [[ $line = 'export default '* ]]; then
            i=${line%%'export default '*}
            line=${line:${#i}+15}
        fi
        if [[ $line = 'export '* ]]; then
            i=${line%%'export '*}
            line=${line:${#i}+7}
        fi
        if [[ ${#line} -gt 0 && ! $line = 'import '* ]]; then
            text+=$line$'\n'
        fi
    done
    texts[$file]=$text
}

build() {
    file=${1:-a/a.js}
    output=${2:-a/y.js}
    imported=()
    imports=($file)
    declare -A modules
    declare -A texts
    while [[ ${#imports[@]} -gt 0 ]]; do
        file=${imports[0]}
        if [[ "${imported[@]}" =~ $file ]]; then
            imports=("${imports[@]:1}")
        else
            parse "$file" "${imported[@]}"
            mods=(${modules[$file]//$'\n'/ })
            if [[ ${#mods[@]} -gt 0 ]]; then
                imports=("${mods[@]}" "${imports[@]}")
            fi
            if [[ "${!texts[@]}" =~ $file ]]; then
                imported+=("$file")
            fi
        fi
    done
    text=''
    imports=()
    for file in "${imported[@]}"; do
        if [[ ! "${imports[@]}" =~ $file ]]; then
            text+=${texts[$file]}
            imports+=("$file")
        fi
    done
    echo -n "$text" > $output
}

build $1 $2