#!/bin/bash






sql2md(){

    local COLOR_OFF='\033[0m'       # Text Reset
    local CYAN='\033[0;36m'
    local BURPLE='\033[1;95m'
    local YELLA='\033[1;33m'
    local ON_BLACK='\033[40m'
    local ON_WHITE='\033[0;107m'

    local dbfile=''
    local kramtableclass=''
    local sqlquery=''
    # http://stackoverflow.com/questions/1167746/how-to-assign-a-heredoc-value-to-a-variable-in-bash
    read -r -d '' sqliteconfigcode <<-'EOF'
.headers on
.mode csv
.nullvalue NULL
EOF

	# getopts is sweeeet...

	# http://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash-script
	# http://stackoverflow.com/questions/16654607/using-getopts-inside-a-bash-function
    local OPTIND d
    while getopts ':c:d:pr' flag; do
      case "${flag}" in
        c) local csstableclass="${OPTARG}" ;;
        d) local dbfile="${OPTARG}" ;;
        p) local usepbpaste='true' ;;
        r) local raw_output='true' ;;
#        l) limitrows="${OPTARG}" ;;
        # v) verbose='true' ;;

        *) error "Unexpected option ${flag}" ;;
      esac
    done
    shift "$((OPTIND - 1))"
    (>&2 printf "\n${YELLA}##########################${COLOR_OFF}\n")

    # Print the setup commands for sqlite
    (>&2 printf "${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}"    "SQLite config"      "$sqliteconfigcode")





    # Check to see if a database file is referenced
    if [[ -n $dbfile ]]; then
    	(>&2 printf "${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}\n"   "Using database file" "$dbfile")
    else
        (>&2 printf "${ON_BLACK}${CYAN}%s${COLOR_OFF}\n" "No database")
    fi

    # print out raw output or not?
    if [[ -n $raw_output ]]; then
        (>&2 printf "${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}\n"   "Output" "Raw")
    else
        (>&2 printf "${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}\n"   "Output" "Markdown")

        # Set the table style
        if [[ -z $csstableclass ]]; then
            csstableclass=".table-sql"
        fi

        (>&2 printf "${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}\n"  "CSS table selector" "$csstableclass")

    fi

    # if usepbpaste is true, it overrides any SQL string passed in as an argument
    # Check to see if a database file is referenced
    if [[ -n $usepbpaste ]]; then
        (>&2 printf "${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}\n"   "Query source" "pbpaste")
        sqlquery="$(pbpaste)"
    else
        (>&2 printf "${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}\n"   "Query source" "arg-1")
        sqlquery="$1"
    fi

    # print the query code
    (>&2 printf "${ON_BLACK}${BURPLE}%s:\n${CYAN}%s\n${COLOR_OFF}"    "Query"              "$sqlquery")




    # a block of yellow to deliinate the actual response to stdout
    (>&2 printf "\n${YELLA}##########################${COLOR_OFF}\n")

    ##### End of stderr
    if [[ -n $raw_output ]]; then
        # just the data
        echo "${sqliteconfigcode}
              ${sqlquery}" \
            | sqlite3 "${dbfile}"
    else
        # print out the SQL query as Markdown
        printf "\n~~~sql\n"
        echo "$sqlquery"
        printf "~~~\n\n"

        # finally, execute the query on SQLite
        echo "${sqliteconfigcode}
              ${sqlquery}" \
            | sqlite3 "${dbfile}" \
            | csvlook \
            | sed '1d' \
            | sed '$ d'

        # tack on the Kramdown selector
        printf "{:$csstableclass}\n"

    fi

}
