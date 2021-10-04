#!/bin/bash

REPO_URL='http://repo.percona.com/'

REPO_DATA="$( cat repo-index.html )"

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
	REPO_PRODUCT_VERSIONS=( $( echo "$REPO_DATA" | grep '<a href="'"$REPO_PRODUCT_SELECTOR" | sed -e 's@.*<a href="'"$REPO_PRODUCT_PREFIX"'\([^/]\+\)/".*>@\1@' ) )

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
	local lineNumber=$( echo "$REPO_DATA" | grep -n  "$REPO_PRODUCT_SELECTOR" | tail -n 1 | cut -d: -f1 )
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
	done
}

PRODUCT_URL='https://www.percona.com/downloads/percona-postgresql-11/LATEST/'
PRODUCT_NAME='Percona Distribution for PostgreSQL 11'
PRODUCT_SELECTOR='Percona Distribution for PostgreSQL 11'
PRODUCT_PREFIX='percona-postgresql-11/'

REPO_PRODUCT_SELECTOR='ppg-11\.'
REPO_PRODUCT_PREFIX='ppg-'

checkProduct
updateRepoData

PRODUCT_URL='https://www.percona.com/downloads/postgresql-distribution-12/LATEST/'
PRODUCT_NAME='Percona Distribution for PostgreSQL 12'
PRODUCT_SELECTOR='Percona Distribution for PostgreSQL 12'
PRODUCT_PREFIX='postgresql-distribution-12/'

REPO_PRODUCT_SELECTOR='ppg-12\.'
REPO_PRODUCT_PREFIX='ppg-'

checkProduct
updateRepoData

PRODUCT_URL='https://www.percona.com/downloads/postgresql-distribution-13/LATEST/'
PRODUCT_NAME='Percona Distribution for PostgreSQL 13'
PRODUCT_SELECTOR='Percona Distribution for PostgreSQL 13'
PRODUCT_PREFIX='postgresql-distribution-13/'

REPO_PRODUCT_SELECTOR='ppg-13\.'
REPO_PRODUCT_PREFIX='ppg-'

checkProduct
updateRepoData

PRODUCT_URL='https://www.percona.com/downloads/percona-distribution-mongodb-4.2/LATEST/'
PRODUCT_NAME='Percona Distribution for MongoDB 4.2'
PRODUCT_SELECTOR='percona distribution mongodb 4.2'
PRODUCT_PREFIX='percona-distribution-mongodb-4.2/percona-distribution-mongodb-'

REPO_PRODUCT_SELECTOR='pdmdb-4.2\.'
REPO_PRODUCT_PREFIX='pdmdb-'

checkProduct
updateRepoData

PRODUCT_URL='https://www.percona.com/downloads/percona-distribution-mongodb-4.4/LATEST/'
PRODUCT_NAME='Percona Distribution for MongoDB 4.4'
PRODUCT_SELECTOR='percona distribution mongodb 4.4'
PRODUCT_PREFIX='percona-distribution-mongodb-4.4/percona-distribution-mongodb-'

REPO_PRODUCT_SELECTOR='pdmdb-4.4\.'
REPO_PRODUCT_PREFIX='pdmdb-'

checkProduct
updateRepoData

PRODUCT_URL='https://www.percona.com/downloads/percona-distribution-mysql-ps/LATEST/'
PRODUCT_NAME='Percona Distribution for MySQL (ps)'
PRODUCT_SELECTOR='percona distribution mysql ps 8.0'
PRODUCT_PREFIX='percona-distribution-mysql-ps/percona-distribution-mysql-ps-'

REPO_PRODUCT_SELECTOR='pdps-8.0\.'
REPO_PRODUCT_PREFIX='pdps-'

checkProduct
updateRepoData

PRODUCT_URL='https://www.percona.com/downloads/percona-distribution-mysql-pxc/LATEST/'
PRODUCT_NAME='Percona Distribution for MySQL (pxc)'
PRODUCT_SELECTOR='percona distribution mysql pxc 8.0'
PRODUCT_PREFIX='percona-distribution-mysql-pxc/percona-distribution-mysql-pxc-'

REPO_PRODUCT_SELECTOR='pdpxc-8.0\.'
REPO_PRODUCT_PREFIX='pdpxc-'

checkProduct
updateRepoData

### ### PRODUCT_URL='https://www.percona.com/downloads/percona-server-mongodb-3.6/LATEST/'
### ### PRODUCT_NAME='Percona Server for MongoDB 3.6'
### ### PRODUCT_SELECTOR='Percona Server for MongoDB 3.6'
### ### PRODUCT_PREFIX='percona-server-mongodb-3.6/percona-server-mongodb-'
### ### 
### ### REPO_PRODUCT_SELECTOR='psmdb-36'
### ### REPO_PRODUCT_PREFIX='psmdb-'
### ### 
### ### checkProduct
### ### updateRepoData
### ### 
### ### PRODUCT_URL='https://www.percona.com/downloads/percona-server-mongodb-4.0/LATEST/'
### ### PRODUCT_NAME='Percona Server for MongoDB 4.0'
### ### PRODUCT_SELECTOR='Percona Server for MongoDB 4.0'
### ### PRODUCT_PREFIX='percona-server-mongodb-4.0/percona-server-mongodb-'
### ### 
### ### REPO_PRODUCT_SELECTOR='psmdb-40'
### ### REPO_PRODUCT_PREFIX='psmdb-'
### ### 
### ### checkProduct
### ### updateRepoData
### ### 
### ### PRODUCT_URL='https://www.percona.com/downloads/percona-server-mongodb-4.2/LATEST/'
### ### PRODUCT_NAME='Percona Server for MongoDB 4.2'
### ### PRODUCT_SELECTOR='Percona Server for MongoDB 4.2'
### ### PRODUCT_PREFIX='percona-server-mongodb-4.2/percona-server-mongodb-'
### ### 
### ### REPO_PRODUCT_SELECTOR='psmdb-42'
### ### REPO_PRODUCT_PREFIX='psmdb-'
### ### 
### ### checkProduct
### ### updateRepoData
### ### 
### ### PRODUCT_URL='https://www.percona.com/downloads/percona-server-mongodb-LATEST/'
### ### PRODUCT_NAME='Percona Server for MongoDB 4.4'
### ### PRODUCT_SELECTOR='Percona Server for MongoDB 4.4'
### ### PRODUCT_PREFIX='percona-server-mongodb-LATEST/percona-server-mongodb-'
### ### 
### ### REPO_PRODUCT_SELECTOR='psmdb-44'
### ### REPO_PRODUCT_PREFIX='psmdb-'
### ### 
### ### checkProduct
### ### updateRepoData
### ### 
### ### PRODUCT_URL='https://www.percona.com/downloads/percona-server-mongodb-5.0/LATEST/'
### ### PRODUCT_NAME='Percona Server for MongoDB 5.0'
### ### PRODUCT_SELECTOR='Percona Server for MongoDB 5.0'
### ### PRODUCT_PREFIX='percona-server-mongodb-5.0/percona-server-mongodb-'
### ### 
### ### REPO_PRODUCT_SELECTOR='psmdb-50'
### ### REPO_PRODUCT_PREFIX='psmdb-'
### ### 
### ### checkProduct
### ### updateRepoData
### 
### ### PRODUCT_URL="https://www.percona.com/downloads/Percona-Server-5.6/LATEST/"
### ### PRODUCT_NAME='Percona Server for MySQL 5.6'
### ### PRODUCT_SELECTOR='Percona Server for MySQL 5.6'
### ### PRODUCT_PREFIX='Percona-Server-5.6/Percona-Server-'
### ### 
### ### REPO_PRODUCT_SELECTOR='ps-56'
### ### REPO_PRODUCT_PREFIX='ps-'
### ### 
### ### checkProduct
### ### updateRepoData
### ### 
### ### PRODUCT_URL="https://www.percona.com/downloads/Percona-Server-5.7/LATEST/"
### ### PRODUCT_NAME='Percona Server for MySQL 5.7'
### ### PRODUCT_SELECTOR='Percona Server for MySQL 5.7'
### ### PRODUCT_PREFIX='Percona-Server-5.7/Percona-Server-'
### ### 
### ### REPO_PRODUCT_SELECTOR='ps-57'
### ### REPO_PRODUCT_PREFIX='ps-'
### ### 
### ### checkProduct
### ### updateRepoData
### ### 
### ### PRODUCT_URL="https://www.percona.com/downloads/Percona-Server-LATEST/"
### ### PRODUCT_NAME='Percona Server for MySQL 8.0'
### ### PRODUCT_SELECTOR='Percona Server for MySQL 8.0'
### ### PRODUCT_PREFIX='Percona-Server-LATEST/Percona-Server-'
### ### 
### ### REPO_PRODUCT_SELECTOR='ps-80'
### ### REPO_PRODUCT_PREFIX='ps-'
### ### 
### ### checkProduct
### ### updateRepoData

echo "$REPO_DATA"

# TODO:
# - Percona Toolkit - pt - https://www.percona.com/downloads/percona-toolkit/LATEST/
# - Percona Monitoring and Management
#   - pmm - https://www.percona.com/downloads/pmm/
#   - pmm2 - https://www.percona.com/downloads/pmm2/
# - Percona Backup for MongoDB - pbm - https://www.percona.com/downloads/percona-backup-mongodb/
# - Percona XtraBackup - pxb - https://www.percona.com/downloads/Percona-XtraBackup-2.4/LATEST/ https://www.percona.com/downloads/Percona-XtraBackup-LATEST/
