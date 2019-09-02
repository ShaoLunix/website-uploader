#!/bin/bash

#============#
# FUNCTIONS  #
#============#

# Abnormal exit
abnormalExit()
{
    echo "$myscript -- End -- Failed"
    exit 2
}

# Prerequisite not met
prerequisitenotmet()
{
    echo "$missingcommands : missing"
    echo "Please, install it first and check you can access '$missingcommands'."
    echo "Programm aborted."
    exit 1
}

# Aborting the script because of a wrong or missing parameter
usage()
{
    echo "Usage: $myscript [-b BACKUP_OPTION] [-c CONFIG_FILE] [-p SSH_PASSWORD [-d]] [-f LIST_OF_FILES]" \
                    "[-h] [-k] [-l LOCAL_WEBSITE_PATH] [-n] [-r REMOTE_SERVER_HOSTNAME] [-s WEB_SERVER_NAME]" \
                    "[-u SSH_USER] [-v]"
    echo "For more information on how to use the script, type : < $myscript -h >"
    echo "$myscript -- End -- failed"
    exit 1
}

# Display the help of this script
displayhelp()
{
    echo "${myscript^^}"
    echo
    echo "Syntax : $myscript [OPTION ...]"
    echo "This script uploads files to a remote server according to the values passed with the arguments '-bcdfklnprsu'." \
         "This is very useful to update files on a web server without having to connect to it and do it manually."
    echo
    echo "With no option, the command loads the default configuration file declared in the '$myscript.conf' file."
    echo
    echo "The general configuration file is firstly loaded ('$myscript.conf')."
    echo "Then the configuration file declared in that general configuration file" \
         "which contains the values specific to the machine you upload from and to the server you upload to."
    echo "At last, the options are read from the command line."
    echo "That means, the command line options overwrite the variables used by the script." \
         "This can be very useful when exceptionally the files are uploaded to a server with some unusual options."
    echo "For example to upload files to a preprod server which is identical to a production one but its hostname." \
         "Then the same configuration file can be included and the option '-r' specified with a different REMOTE_SERVER_HOSTNAME."
    echo
    echo "$myscript [-b BACKUP_OPTION] [-c CONFIG_FILE] [-p SSH_PASSWORD [-d]] [-f LIST_OF_FILES]" \
                    "[-k] [-l LOCAL_WEBSITE_PATH] [-n] [-r REMOTE_SERVER_HOSTNAME] [-s WEB_SERVER_NAME]" \
                    "[-u SSH_USER]"
    echo "$myscript [-h]"
    echo "$myscript [-v]"
    echo
    echo " OPTIONS"
    echo
    echo "  -b :        The backup option is enabled/disabled. If this option is enabled then" \
                        "a backup folder is created (if it does not already exists) and a timestamp folder" \
                        "is created in it. That folder contains the backed up file(s)."
    echo "              The argument BACKUP_OPTION can be one of the following :"
    echo "              - 'off' : no backup. This argument disables the backup option. It is the default status."
    echo "              - 'in'  : each folder contains its own backup folder."
    echo "              - 'out' : the tree of folders is copied to a general backup folder in the root folder."
    echo "  -c :        The configuration file to include."
    echo "  -d :        If this option is used then the password following the '-p' option will be decrypted before being used."
    echo "  -f :        The file containing the list of files (regular ones or folders) to send to the remote server."
    echo "  -h :        Display the help."
    echo "  -k :        The files are sent in a compressed format (bz2) to speed up the upload." \
                        "The files are compressed locally before being sent then uncompressed once on the server." \
                        "Then the local and the remote compressed files are removed automatically."
    echo "  -l :        The local website path."
    echo "  -n :        The number of transfers is displayed before each transfer." \
                        "At the end, the total amount of transfers is displayed." \
                        "That number is incremented before each try. Therefore, it doesnot represent only succeeded transfers."
    echo "  -p :        The SSH user's password. With the option '-d', the password will be decrypted before being used."
    echo "  -r :        The website path on the remote server."
    echo "  -s :        The web server's hostname."
    echo "  -u :        The SSH username to use to connect to the remote web server."
    echo "  -v :        This script version."
    echo
    echo "Exit status : "
    echo " 0 = success"
    echo " 1 = failure due to wrong parameters"
    echo " 2 = abnormal exit"
    echo
    echo "To inform about any problem : $mycontact."
    exit
}

# Loading the configuration file
load_configfile()
{
    # If the configuration file is set with a relative path
    # Then it is converted to absolute
    if [[ "$configuration_file" != /* ]]
        then
            script_dir="$( cd "$( dirname "$0" )" && pwd )"
            configuration_file="$script_dir/$configuration_file"
    fi

    # Loading the configuration file only if it exists
    # Else exit with an error
    if [ ! -f "$configuration_file" ]
        then
            echo "$configuration_file could not be found."
            exit 1
        else
            . "$configuration_file"
    fi
}

# Password decryption
decrypt_password()
{
    decryptedpass=$(./storepass.sh -d "decrypted" "$ssh_pass")
    # Exiting if the decrypted password is wrong
    if [ -z "$decryptedpass" ]
        then
            echo "Something went wrong with the decryption of the password."
            usage
    fi
}

# Substring replacement
#   Substitute to the local path ($2) in the line (string $1) the remote path ($3)
#
#	@parameter $1 : string to modify (hay)
#	@parameter $2 : string substring to be replaced (needle)
#	@parameter $3 : string new substring
#	@return string new string
string_replace()
{
	echo "${1/$2/$3}"
}

# Backing up
backup()
{
	# Backing up the file
	case "$backup" in
    	"in")
        	destBackupFolder=$(dirname $fileTobeUpdated)"/backup/$currentTime"
        	;;
    	"out")
            subfolder=${fileTobeUpdated#"$remote_website_root/"}
            subfolder=${subfolder%/*}
            destBackupFolder="$remote_website_root/backup/$subfolder/$currentTime"
        	;;
    	\? ) # invalid option
    	    usage
    	    ;;
	esac
	destBackedupFile=$destBackupFolder/$filename

    # back up is done only on an existing file
    if [[ $(sshpass -p "$decryptedpass" ssh -n -p "$ssh_port" "$ssh_user@$ssh_server" "ls $fileTobeUpdated 2>&1 /dev/null; exit;") ]]
        then
	        echo -e "backing up : $fileTobeUpdated to $destBackedupFile"
	        # backing up the remote file to a remote backup directory
	        sshpass -p "$decryptedpass" \
                        ssh -n -p "$ssh_port" "$ssh_user@$ssh_server" \
                        "mkdir -p $destBackupFolder && " \
                        "cp -fR $fileTobeUpdated $destBackedupFile; " \
                        "exit"

	        # and checking if backup is ok
	        if [[ $(sshpass -p "$decryptedpass" ssh -n -p "$ssh_port" "$ssh_user@$ssh_server" "ls $destBackedupFile 2>&1 /dev/null; exit;") ]]
	            then
		            echo "file backup : ok"
	            else
		            echo "file couldnot be backed up properly ... abortion"
		            exit 0
	        fi
    fi
}

# Compressing file
compress()
{
    #compressfolder=${line%/*}
    compressfolder=$(dirname $line)
    #compressedfile="$compressfolder/$filename.bz2"
    compressedfile="$filename.bz2"
    # compressing through the bzip2 filter
    tar -cj -C "$compressfolder" -f "$compressedfile" "$filename"
}

# Uncompressing file
uncompress()
{
    # uncompressing through the bzip2 filter
    tar -xjf "$compressfolder/$filename.bz2"
}

# Removing local compressed file
remove_local_compressedfile()
{
    \rm -f "$compressfolder/$filename.bz2"
}



# Transferring the files
transfer()
{
    # Declaration of the destination folder
    destFolder=$(dirname $fileTobeUpdated)
    # according to the type of the file (regular file or directory)
#    if [ -f "$line" ]
#        then destFolder=$(dirname $fileTobeUpdated)
#    elif [ -d "$line" ]
#        then destFolder=$(dirname $fileTobeUpdated)
#    fi

    # The transfer procedure is slightly different
    # according to if the compression is used or not
	case "$iscompressed" in
	    # Compressed file
	    true )
                compress

                # Creation of the destination path if it does not exist
                sshpass -p "$decryptedpass" \
                            ssh -n -p "$ssh_port" "$ssh_user@$ssh_server" \
                            "mkdir -p $destFolder; " \
                            "exit"
                # Sending the file to the destination folder on the remote server
                sshpass -p "$decryptedpass" \
                            scp -P "$ssh_port" "$compressedfile" "$ssh_user@$ssh_server:$destFolder"
                # Uncompressing the file on the remote server
                sshpass -p "$decryptedpass" \
                            ssh -n -p "$ssh_port" "$ssh_user@$ssh_server" \
                            "tar -xjf $destFolder/$filename.bz2 --overwrite -C $destFolder/; " \
                            "rm -fR $destFolder/$filename.bz2; " \
                            "exit"

	            # Checking if transfer is ok
	            check_transfer
                # Removing the local compressed file
                remove_local_compressedfile
                ;;

        # Not compressed file
        false )
                # Creation of the destination path if it does not exist
                sshpass -p "$decryptedpass" \
                            ssh -n -p "$ssh_port" "$ssh_user@$ssh_server" \
                            "mkdir -p $destFolder; " \
                            "exit"
                # Sending the file to the destination folder on the remote server
                sshpass -p "$decryptedpass" \
                            scp -P "$ssh_port" "$line" "$ssh_user@$ssh_server:$fileTobeUpdated"

	            # Checking if transfer is ok
	            check_transfer
                ;;
    esac
}



# Checking the transferred files
check_transfer()
{
	# checking if transfer is ok
	if sshpass -p "$decryptedpass" ssh -n -p "$ssh_port" "$ssh_user@$ssh_server" "ls $fileTobeUpdated; exit;" 2>&1 /dev/null
	    then echo "file transferred."
	    else echo "file couldnot be transferred."
	fi
}

