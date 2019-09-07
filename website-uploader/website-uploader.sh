#!/bin/bash

#==============================================================================#
#
#       WEBSITE-UPLOADER
#
# This script uploads files to a remote server.
# This is very useful to update files on a web server without having
# to connect to it and do it manually.
#
# Versions
# [2019-09-02] [1.0] [Stéphane-Hervé] First version
#==============================================================================#
# strict mode
set -o nounset


#=== THIS SCRIPT DETAILS
VER=1.0
myscript="website-uploader"
myproject="$myscript"
mycontact="https://github.com/ShaoLunix/$myproject/issues"



#*** CHECKING IF THE CURRENT SCRIPT CAN BE EXECUTED
#*** root is forbidden
myidentity=$(whoami)
if [ $myidentity = "root" ]
then
	RED='\033[0;31m'
	GREEN='\033[0m'
	echo -e "${RED}this script cannot be executed as root${GREEN}\n"
	exit
fi



#=== FUNCTIONS FILE
. functions.sh



#===========#
# VARIABLES #
#===========#
# Required commands
requiredcommand_1="sshpass"
missingcommands=""
# Params
script_configfile="website-uploader.conf"
list_of_files="listof-files-tobe-transferred"
backup="off"
isbackup=false
decryptedpass=""
isdecrypt=false
iscompressed=false
sourcetype=""
compressfolder=""
compressedfile=""
iscounteron=false
counter=""
local_website_root=""
remote_website_root=""
ssh_server=""
ssh_user=""
ssh_pass=""
isssh_pass=false
# Time
currentTime=$(date +"%Y%m%d"_"%H%M%S")



#=== CONFIGURATION FILE
. "$script_configfile"
# Loading the configuration file
load_configfile



#=== MANAGING EXIT SIGNALS
trap 'abnormalExit' 1 2 3 4 15



#====================#
# TEST PREREQUISITES #
#====================#
if ! type $requiredcommand_1 > /dev/null 2>&1
    then
        missingcommands="$requiredcommand_1"
fi
#if ! type "$requiredcommand_2" > /dev/null 2>&1
#    then
#        if -z "$missingcommands" > /dev/null 2>&1
#            then missingcommands="$missingcommands and $requiredcommand_2"
#            else missingcommands="$requiredcommand_2"
#        fi
#fi
if -z "$missingcommands" > /dev/null 2>&1
    then prerequisitenotmet $missingcommands
fi



#=======#
# FLAGS #
#=======#
# -b : the backup option :
#       - off : no backup
#       - in : each folder contains its own backup folder
#       - out : the tree of folders is copied to a general backup folder in the root folder
# -c : the configuration file to consider
# -d : if this option is present then the password following the option '-p' must be decrypted
# -f : the list of files to send to the remote web server
# -h : display the help
# -k : files are sent in compressed format (bz2) to speed up the upload
# -l : the local website path
# -n : number of transfers. It starts every transfer with its number
# -p : SSH user's password. With the option '-d', the password must be decrypted.
# -r : the remote website path
# -s : web server name
# -u : SSH user to use to connect to the web server
# -v : this script version

while getopts "b:c:df:hkl:np:r:s:u:v" option
do
    case "$option" in
        b)
            backup=${OPTARG}
            case "$backup" in
                "in" | "IN")
                    backup="in"
                    isbackup=true
                    ;;
                "out" | "OUT")
                    backup="out"
                    isbackup=true
                    ;;
                \? )
                    backup="off"
                    isbackup=false
                    ;;
            esac
            ;;
        c)
            configuration_file=${OPTARG}
            # Loading the configuration file
            load_configfile
            # Getting the decrypted password
            decrypt_password
            ;;
        d)
            isdecrypt=true
            ;;
        f)
            list_of_files=${OPTARG}
            ;;
        h)
            displayhelp
            exit "$exitstatus"
            ;;
        k)
            iscompressed=true
            ;;
        l)
            local_website_root=${OPTARG}
            ;;
        n)
            counter=0
            iscounteron=true
            ;;
        p)
            ssh_pass=${OPTARG}
            isssh_pass=true
            ;;
        r)
            remote_website_root=${OPTARG}
            ;;
        s)
            ssh_server=${OPTARG}
            ;;
        u)
            ssh_user=${OPTARG}
            ;;
        v)
            echo "$myscript -- Version $VER -- Start"
            date
            exit "$exitstatus"
            ;;
        \? )
            # For invalid option
            usage
            ;;
    esac
done



#=============#
# PREPARATION #
#=============#
# If the password must be decrypted
# Then execute the decrypt function
# Else the decrypted password is as it was passed
if [ "$isdecrypt" == true ] && [ "$isssh_pass" == true ]
    then
        decrypt_password
elif [ "$isdecrypt" == false ] && [ "$isssh_pass" == true ]
    then
        decryptedpass="$ssh_pass"
fi



#======#
# MAIN #
#======#
#*** READING FILES TO BE TRANSFERRED ***
#*** and ...
#*** - backing up their equivalent in production server (online) before any change
#*** - Transferring them from preprod server to prod server
while read line
do
	# Checking if current line is not empty
	if [[ ! -z "$line" ]] && [[ "$line" != \#* ]]
	then
		(( counter++ ))
		echo "$counter"

		filename=$(basename $line)
		fileTobeUpdated=$(string_replace "$line" "$local_website_root" "$remote_website_root")

		#*** BACKUP
		if [[ "$isbackup" == true ]] && [[ "$backup" != "off" ]]; then backup; fi

		#*** TRANSFER
		# Transferring the file from development to preproduction
		echo -e "transferring : "$line" to "$fileTobeUpdated
        transfer
		echo
		# Incrementing the counter of transfers
	fi
done < "$list_of_files"

echo "number of transfers : $counter."

exit 0
