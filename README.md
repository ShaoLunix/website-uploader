# website-uploader
This script uploads files to a remote server according to the values passed with the arguments '-bcdfklnprsu'. This is very useful to update files on a web server without having to connect to it and do it manually.

With no option, the command loads the default configuration file declared in the 'website-uploader.conf' file.

The general configuration file is firstly loaded ('website-uploader.conf').
Then the configuration file declared in that general configuration file which contains the values specific to the machine you upload from and to the server you upload to.
At last, the options are read from the command line.
That means, the command line options overwrite the variables used by the script. This can be very useful when exceptionally the files are uploaded to a server with some unusual options.
For example to upload files to a preprod server which is identical to a production one but its hostname. Then the same configuration file can be included and the option '-r' specified with a different REMOTE_SERVER_HOSTNAME.

website-uploader [-b BACKUP_OPTION] [-c CONFIG_FILE] [-p SSH_PASSWORD [-d]] [-f LIST_OF_FILES] [-k] [-l LOCAL_WEBSITE_PATH] [-n] [-r REMOTE_SERVER_HOSTNAME] [-s WEB_SERVER_NAME] [-u SSH_USER]

website-uploader [-h]

website-uploader [-v]

 OPTIONS

  -b :        The backup option is enabled/disabled. If this option is enabled then a backup folder is created (if it does not already exists) and a timestamp folder is created in it. That folder contains the backed up file(s).
  
              The argument BACKUP_OPTION can be one of the following :
              - 'off' : no backup. This argument disables the backup option. It is the default status.
              - 'in'  : each folder contains its own backup folder.
              - 'out' : the tree of folders is copied to a general backup folder in the root folder.
              
  -c :        The configuration file to include.
  
  -d :        If this option is used then the password following the '-p' option will be decrypted before being used.
  
  -f :        The file containing the list of files (regular ones or folders) to send to the remote server.
  
  -h :        Display the help.
  
  -k :        The files are sent in a compressed format (bz2) to speed up the upload. The files are compressed locally before being sent then uncompressed once on the server. Then the local and the remote compressed files are removed automatically.
  
  -l :        The local website path.
  
  -n :        The number of transfers is displayed before each transfer. At the end, the total amount of transfers is displayed. That number is incremented before each try. Therefore, it doesnot represent only succeeded transfers.
  
  -p :        The SSH user's password. With the option '-d', the password will be decrypted before being used.
  
  -r :        The website path on the remote server.
  
  -s :        The web server's hostname.
  
  -u :        The SSH username to use to connect to the remote web server.
  
  -v :        This script version.

Exit status :

 0 = success ;  1 = failure due to wrong parameters ;  2 = abnormal exit
 
To inform about any problem : https://github.com/ShaoLunix/website-uploader/issues.
