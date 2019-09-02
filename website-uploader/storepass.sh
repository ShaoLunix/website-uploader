#!/bin/bash

#==============================================================================#
#
#       STOREPASS
#
# This script encrypts/decrypts the password passed as an argument.
# It also stores it, after encryption, into the server configuration file
# declared in the main script's general configuration file.
#
# Versions
# [2019-09-02] [1.0] [Stéphane-Hervé] First version
#==============================================================================#
# strict mode
set -o nounset

#=== CONFIGURATION FILE
. website-uploader.conf
. "$configuration_file"

#=== THIS SCRIPT DETAILS
VER=1.0
myscript="storepass"
myproject="website-uploader"
mycontact="https://github.com/ShaoLunix/$myproject/issues"



#===========#
# VARIABLES #
#===========#
# Required commands
requiredcommand="openssl"
password=${@: -1}
passphrase="]MK0U3;Rm;U}1Nw"
encryptedpass=""
decryptedpass=""
display_pass="off"
isdisplayed=false
isprotocol=false
declare -a protocol
protocol=( "ftp" "ssh" )



#===========#
# FUNCTIONS #
#===========#
# Abnormal exit
abnormalExit()
{
    echo "$myscript -- End -- Failed"
    exit 2
}

# Prerequisite not met
prerequisitenotmet()
{
    echo "$requiredcommand : missing"
    echo "Please, install it first and check you can access '$requiredcommand'."
    echo "Programm aborted."
    exit 1
}

# Aborting the script because of a wrong or missing parameter
usage()
{
    echo "Usage: $myscript [-d PASSWORD_STATUS] [-p PROTOCOL] PASSWORD"
    echo "For more information on how to use the script, type : < $myscript -h >"
    echo "$myscript -- End -- failed"
    exit 1
}

# Display the help of this script
displayhelp()
{
    echo "Syntax : $myscript [OPTION ...]"
    echo "$myscript encrypts the password passed in argument."
    echo "With no option, the command returns an error"
    echo
    echo "$myscript [-p PROTOCOL] PASSWORD"
    echo "$myscript [-d PASSWORD_STATUS] PASSWORD"
    echo "$myscript [-h]"
    echo "$myscript [-v]"
    echo
    echo "  -d :        display the encrypted or decrypted password. The PASSWORD_STATUS can be 'encrypted' or 'decrypted'. By default, it is 'off' which means the password will not be displayed."
    echo "  -h :        display the help."
    echo "  -p :        protocol the password is required. The PROTOCOL argument can be 'FTP' or 'SSH' (insensitive case)."
    echo "  -v :        this script version."
    echo
    echo "Exit status : "
    echo " 0 = success"
    echo " 1 = failure due to wrong parameters"
    echo " 2 = abnormal exit"
    echo
    echo "To inform about the problems : $mycontact."
    exit
}

#=== MANAGING EXIT SIGNALS
trap 'abnormalExit' 1 2 3 4 15



#=======#
# Flags #
#=======#
# -d : display the encrypted/decrypted password
# -h : display the help
# -p : protocol the password is required
# -v : this script version
while getopts "d:hp:v" option
do
    case "$option" in
        d)
            display_pass=${OPTARG}
            isdisplayed=true
            if [ "$display_pass" != "encrypted" ] && [ "$display_pass" != "decrypted" ] && [ "$display_pass" != "off" ]
                then usage
            fi
            ;;
        h)
            displayhelp
            exit "$exitstatus"
            ;;
        p)
            protocol=${OPTARG}
            protocol=$(echo "$protocol" | awk '{print tolower($0)}')
            isprotocol=true
            if [ "$protocol" != "ftp" ] && [ "$protocol" != "ssh" ]
                then usage
            fi
            ;;
        v)
            echo "$myscript -- Version $VER -- Start"
            date
            exit "$exitstatus"
            ;;
        \? ) # For invalid option
            usage
            ;;
    esac
done



#===============#
# PREREQUISITES #
#===============#
if ! type "$requiredcommand" > /dev/null 2>&1
    then prerequisitenotmet
fi
if [ -z "$password" ]
    then usage
fi



#======#
# MAIN #
#======#
#=== ENCRYPTION/DECRYPTION OF THE PASSWORD
#=== AND WRITING OF THE PASSWORD INTO THE CONFIGURATION FILE ONLY IF 'OFF' argument is on
case "$display_pass" in
    "encrypted")
                # Encrypting the password
                encryptedpass=$(echo "$password" | openssl enc -e -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase")
                echo "$encryptedpass"
                exit
                ;;

    "decrypted")
                # Decrypting the password
                decryptedpass=$(echo "$password" | openssl enc -d -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase" -base64)
                echo "$decryptedpass"
                exit
                ;;

    "off")
                # Encrypting the password
                encryptedpass=$(echo "$password" | openssl enc -e -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase")
                # Decrypting the password
                decryptedpass=$(echo "$encryptedpass" | openssl enc -d -pbkdf2 -md SHA256 -base64) # -nosalt -pass pass:"$passphrase" -base64)

                #=== WRITING OF THE PASSWORD INTO THE CONFIGURATION FILE
                # Testing if the given password is identical to the dehashed password
                # If YES, then the hashed password is written to the configuration file
                if [ "$decryptedpass" == "$password" ]
                    then
                        for proto in "${protocol[@]}"
                        do
                            # If the ssh_pass variable can be found in the configuration file
                            # Then the password replaces the one in the file
                            # Else the line is created at its place
                            if grep -Eq "^$proto"_pass "$configuration_file"
                                then
                                    sed -i -E 's/'"$proto""_pass=\".*\""'/'"$proto""_pass=\"$encryptedpass\""'/g' "$configuration_file"
                                else
                                    sed -i '/'"$proto"'_user/a '"$proto""_pass=\"$encryptedpass\"" "$configuration_file"
                            fi
                        done
                    else
                        echo "Something went wrong with the encryption of the password."
                        abnormalExit
                fi
                ;;

    \?) # For invalid option
                usage
                ;;
esac

exit

