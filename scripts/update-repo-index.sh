#!/bin/bash

REPO_URL='http://repo.percona.com/'

#REPO_DATA="$( cat repo-index.html )"
REPO_DATA="$( wget --quiet -O - $REPO_URL )"

elementIn() {
	local e match="$1"
	shift
	for e
	do
		[[ "$e" == "$match" ]] && return 0
	done
	return 1
}

checkProduct() {
	REPO_VERSION_ADD=()
	REPO_VERSION_DEL=()

	#PRODUCT_DATA="$( cat index.html )"
	PRODUCT_DATA="$( wget --quiet -O - $PRODUCT_URL )"

	# Options: echo "$PRODUCT_DATA" | grep "<option .*$PRODUCT_SELECTOR"
	PRODUCT_VERSIONS=( $( echo "$PRODUCT_DATA" | grep "<option .*$PRODUCT_SELECTOR" | grep -v 'value=""' | sed -e 's@.*<option value="'"$PRODUCT_PREFIX"'\([^"]\+\)" .*</option>@\1@' ) )
	#echo "${PRODUCT_VERSIONS[@]}"

	# Repo versions: echo "$REPO_DATA" | grep '<a href="'"$REPO_PRODUCT_SELECTOR"
	REPO_PRODUCT_VERSIONS=( $( echo "$REPO_DATA" | grep '<a href="'"$REPO_PRODUCT_SELECTOR" | sed -e 's@.*<a href="'"$REPO_PRODUCT_PREFIX"'\([^/]\+\)/".*>@\1@' | uniq ) )

	for v in "${REPO_PRODUCT_VERSIONS[@]}"
	do
		#echo "REPO_PRODUCT_VERSION: $v"
		if ! elementIn "$v" "${PRODUCT_VERSIONS[@]}"
		then
			#echo "'$PRODUCT_NAME': Repository product version '$v' is not in product versions"
			REPO_VERSION_DEL+=( "$v" )
		fi
	done

	for v in "${PRODUCT_VERSIONS[@]}"
	do
		#echo "PRODUCT_VERSION: $v"
		if ! elementIn "$v" "${REPO_PRODUCT_VERSIONS[@]}"
		then
			#echo "'$PRODUCT_NAME': Product version '$v' is not in repository product versions"
			REPO_VERSION_ADD+=( "$v" )
		fi
	done
}

addRepoVersion() {
	# TODO check arguments
	local versionLine="$REPO_PRODUCT_PREFIX$1/"
	local lineNumber=$( echo "$REPO_DATA" | grep -n "$REPO_PRODUCT_SELECTOR" | tail -n 1 | cut -d: -f1 )

	[[ -z "$lineNumber" || "$lineNumber" -eq 0 ]] && { echo 'Can`t find place to add product' >&2; exit 3; }

	(( lineNumber++ ))
	# Maybe awk selector is better here, like awk '/$REPO_PRODUCT_SELECTOR/ { print; print "new line"; next }1'
	echo "$REPO_DATA" | awk "NR==$lineNumber { print "'"            </tr>" RS "            <tr>" RS "              <td><a href=\"'"$versionLine"'\">'"$versionLine"'</a></td>" }1'
}

updateRepoData() {
	#[[ ${#REPO_VERSION_DEL[@]} -ne 0 ]] && echo "'$PRODUCT_NAME' versions that should be removed from repository: ${REPO_VERSION_DEL[@]}"
	#[[ ${#REPO_VERSION_ADD[@]} -ne 0 ]] && echo "'$PRODUCT_NAME' versions that should be added to repository: ${REPO_VERSION_ADD[@]}"
	#[[ ${#REPO_VERSION_ADD[@]} -eq 0 ]] && return
	for v in "${REPO_VERSION_ADD[@]}"
	do
		REPO_DATA=$( addRepoVersion "$v" )
		[[ $? -ne 0 ]] && { echo 'addRepoVersion() failed, exiting with failure' >&2; exit 1; }
	done
}

# Percona Distribution for PostgreSQL
checkAndUpdatePPG() {
	# TODO check arguments
	local PPG_VERSION=$1

	PRODUCT_NAME="Percona Distribution for PostgreSQL $PPG_VERSION"
	PRODUCT_SELECTOR="Percona Distribution for PostgreSQL $PPG_VERSION"
	if [[ $PPG_VERSION -eq 11 ]]
	then
		PRODUCT_URL='https://www.percona.com/downloads/percona-postgresql-11/LATEST/'
		PRODUCT_PREFIX='percona-postgresql-11/'
	else
		PRODUCT_URL="https://www.percona.com/downloads/postgresql-distribution-$PPG_VERSION/LATEST/"
		PRODUCT_PREFIX="postgresql-distribution-$PPG_VERSION/"
	fi

	REPO_PRODUCT_SELECTOR="ppg-$PPG_VERSION\."
	REPO_PRODUCT_PREFIX='ppg-'

	checkProduct
	updateRepoData
}

# Percona Distribution for MongoDB
checkAndUpdatePDMDB() {
	# TODO check arguments
	local PDMDB_VERSION=$1

	PRODUCT_URL="https://www.percona.com/downloads/percona-distribution-mongodb-$PDMDB_VERSION/LATEST/"
	PRODUCT_NAME="Percona Distribution for MongoDB $PDMDB_VERSION"
	PRODUCT_SELECTOR="percona distribution mongodb $PDMDB_VERSION"
	PRODUCT_PREFIX="percona-distribution-mongodb-$PDMDB_VERSION/percona-distribution-mongodb-"

	REPO_PRODUCT_SELECTOR="pdmdb-$PDMDB_VERSION\."
	REPO_PRODUCT_PREFIX='pdmdb-'

	checkProduct
	updateRepoData
}

# Parse command-line arguments into product name and product version
# If second argument is 'new', new product version family is forced
parseProductLine() {
	[[ -z "$1" ]] && { echo "Product line should be provided to parseProductLine" >&2; exit 2; }
	[[ $# -eq 2 && "$2" != 'new' ]] && { echo "Invalid arguments were provided to parseProductLine" >&2; exit 2; }

	local myver="${1/*-/}"
	[[ "$myver" == "$1" ]] && { echo "Product line does not seem to contain version" >&2; exit 2; }

	REPO_PRODUCT_PREFIX="${1%$myver}"
	[[ -z "$REPO_PRODUCT_PREFIX" ]] && { echo "Product line seems to be invalid" >&2; exit 2; }

	if [[ "$2" != 'new' && "$myver" =~ '.' ]]
	then
		local subver="${myver%.*}"
		REPO_PRODUCT_SELECTOR="${REPO_PRODUCT_PREFIX}${subver}\."
	else
		REPO_PRODUCT_SELECTOR="$REPO_PRODUCT_PREFIX"
	fi

	REPO_VERSION_ADD=( "$myver" )
}

for v in '11' '12' '13'
do
	checkAndUpdatePPG $v
done

for v in '4.2' '4.4'
do
	checkAndUpdatePDMDB $v
done


PRODUCT_URL='https://www.percona.com/downloads/percona-distribution-mysql-ps/LATEST/'
PRODUCT_NAME='Percona Distribution for MySQL (ps)'
PRODUCT_SELECTOR='percona distribution mysql ps 8.0'
PRODUCT_PREFIX='percona-distribution-mysql-ps/percona-distribution-mysql-ps-'

REPO_PRODUCT_SELECTOR='pdps-8.0'
REPO_PRODUCT_PREFIX='pdps-'

checkProduct
updateRepoData

PRODUCT_URL='https://www.percona.com/downloads/percona-distribution-mysql-pxc/LATEST/'
PRODUCT_NAME='Percona Distribution for MySQL (pxc)'
PRODUCT_SELECTOR='percona distribution mysql pxc 8.0'
PRODUCT_PREFIX='percona-distribution-mysql-pxc/percona-distribution-mysql-pxc-'

REPO_PRODUCT_SELECTOR='pdpxc-8.0'
REPO_PRODUCT_PREFIX='pdpxc-'

checkProduct
updateRepoData

# Add products from command line
for ver in "${BASH_ARGV[@]}"
do
	parseProductLine "$ver"
	$( addRepoVersion "$v" &> /dev/null ) || parseProductLine "$ver" 'new'
	updateRepoData
done


echo "$REPO_DATA"
