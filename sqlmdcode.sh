#!/bin/bash


COLOR_OFF='\033[0m'       # Text Reset
CYAN='\033[0;36m'
BURPLE='\033[1;95m'
YELLA='\033[1;33m'
ON_BLACK='\033[40m'
ON_WHITE='\033[0;107m'



bsqlmd(){
    dbfile=''
    kramtableclass=''
    sqlquery=''

    # http://stackoverflow.com/questions/1167746/how-to-assign-a-heredoc-value-to-a-variable-in-bash
    read -r -d '' sqliteconfigcode <<-'EOF'
.headers on
.mode csv
.nullvalue NULL
EOF

	# getopts is sweeeet...

	# http://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash-script
	# http://stackoverflow.com/questions/16654607/using-getopts-inside-a-bash-function
    local OPTIND d l
    while getopts 'c:d:p' flag; do
      case "${flag}" in
        c) csstableclass="${OPTARG}" ;;
        d) dbfile="${OPTARG}" ;;
        p) usepbpaste='true' ;;
#        l) limitrows="${OPTARG}" ;;
        # v) verbose='true' ;;

        *) error "Unexpected option ${flag}" ;;
      esac
    done
    shift $((OPTIND-1))

    # if usepbpaste is true, it overrides any SQL string passed in as an argument
    if [[ -n $usepbpaste ]]; then
        sqlquery="$(pbpaste)"
    else
        sqlquery="$1"
    fi

    # Check to see if a database file is referenced
    (>&2 printf "\n${YELLA}##########################${COLOR_OFF}\n")
    if [[ -n $dbfile ]]; then
    	(>&2 printf "\n${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}\n"   "Using database file" "$dbfile")
    else
        (>&2 printf "\n${ON_BLACK}${CYAN}%s${COLOR_OFF}\n" "No database")
    fi

    # Set the table style
    if [[ -z $csstableclass ]]; then
        csstableclass=".table-sql"
    fi

    (>&2 printf "\n${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}\n"  "CSS table selector" "$csstableclass")

    # Print the setup commands for sqlite
    (>&2 printf "\n${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}"    "SQLite config"      "$sqliteconfigcode")

    (>&2 printf "\n${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}"    "Query"              "$sqlquery")


    # a block of yellow to deliinate the actual response to stdout
    (>&2 printf "\n${YELLA}##########################${COLOR_OFF}\n")

    ##### End of stderr


    # print out the SQL query as Markdown
    printf "\n~~~sql\n${sqlquery}\n~~~\n\n\n"

    # finally, execute the query on SQLite
	printf "${sqliteconfigcode}\n${sqlquery}" \
        | sqlite3 "${dbfile}" \
        | csvlook \
        | sed '1d' \
        | sed '$ d'
#        | awk '1; END {print "{:.table-sql}"}'
# screw it use csvkit


#        | sed -e 's/^/| /' -e 's/,/,| /g' -e 's/$/,|/' | column -t -s,
#sed -e 's/^/| /' -e 's/,/,| /g' -e 's/$/,|/' | column -t -s,
        # \
        # | column -t

	# tack on the Kramdown selector
	printf "{:$csstableclass}\n"

}
