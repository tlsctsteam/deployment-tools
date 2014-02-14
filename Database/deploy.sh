#!/bin/bash

# Script:      deploy.sh
# Purpose:     Used to deploy database objects and release scripts from SVN
# Usage:       deploy.sh [-d|-s] [trunk|{tag-name}{branch-name}]
#               or
#              deploy.sh update to update the script itself from SVN
#
# Examples:    deploy.sh trunk
#              deploy.sh TLSDEV-999
#              deploy.sh 1.6.999
#
# Notes:       -d flag writes lots of additional debug information to the log
#              -s flag suppresses prompts
#              update downloads the latest version of the script from SVN
#
# History
# -----------------------------------------------------------------------------
# 07.10.2013   Andy Neale   Initial version
# 01.11.2013   Andy Neale   Added validation of folder list definition
# 06.11.2013   Andy Neale   Additional security involving file actions
# 12.11.2013   Andy Neale   Minor bug fixes
# 13.11.2013   Andy Neale   Set execute permission for .sh scripts and
#                            convert files from DOS to Unix format
# 13.11.2013   Andy Neale   Added ability for script to update itself from SVN
# 14.11.2013   Andy Neale   Added load scripts to list of objects to deploy
# 22.11.2013   Andy Neale   Create logs directory if it doesn't already exist
# 25.11.2013   Andy Neale   Also deploy core and site data folders
# 02.12.2013   Andy Neale   Allow core and site tools folders
# 02.12.2013   Andy Neale   Re-formatted find statements to avoid using
#                            wholename predicate, not available in all systems
# 02.12.2013   Andy Neale   Make sure the update option runs in /home/vol1/utils
# 11.12.2013   Andy Neale   Only create symbolic links if they don't exist
# 13.12.2013   Andy Neale   Fixed weird bug in logic that checks if links needed
# 10.01.2014   Andy Neale   Don't change file format or execute permissions of
#                            files, this is now done via SVN auto-props
# -----------------------------------------------------------------------------


# --------|   Set default values for options   |--------

debug="N"
silent="N"


# --------|   Parse command-line arguments   |--------

if [ "$1" = "update" ] ; then
  echo "Exporting from SVN..."
  pwd=`pwd`
  cd /home/vol1/utils
  svn export --username TLS.Build --password army-m3tro https://svn.collinsontech.com/GMS/Projects/gms-internal-dba-tools/Production%20Systems%20Support%20scripts/Deployment/Database/deploy.sh
  perl -pi -e 's/\r\n/\n/;' deploy.sh
  chmod 755 deploy.sh
  cd $pwd
  exit 0 
fi

while getopts ":ds" opt ; do
  case $opt in
    d)
      debug="Y" ;;
    s)
      silent="Y" ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1 ;;
  esac
done
shift $((OPTIND-1))

if [ $# -lt 1 ] ; then
  echo "Usage: deploy.sh update|[-d|-s] [trunk|{tag-name}{branch-name}]"
  exit 1
fi


# --------|   Set logging parameters   |--------

now=`date +%F-%T`                  # Date and time in YYYY-mm-dd HH:MM:SS format
log_summary=$HOME/logs/deploy_summary.log
log_detail=$HOME/logs/deploy_detail_$now.log

# Make sure log files exist (create if necessary) and are writeable

if [ ! -d "$HOME/logs" ] ; then
  mkdir $HOME/logs
fi
if [ ! -e "$log_summary" ] ; then
  touch "$log_summary" 2> /dev/null
fi
if [ ! -w "$log_summary" ] ; then
  echo "Error - cannot write to summary log file"
  exit 1
fi

if [ ! -e "$log_detail" ] ; then
  touch "$log_detail" /dev/null
fi
if [ ! -w "$log_detail" ] ; then
  echo "Error - cannot write to detail log file"
  exit 1
fi


# --------|   Work out what environment we are working in   |--------

dbname=`whoami`
if [ "$dbname" = "" ] ; then
  echo "Error - unable to identify target database"
  exit 1
fi
if [ "$dbname" = "arm_dev" ] ; then
  dbname="ihg_dev"
fi


# --------|   Get user confirmation before continuing...   |--------

if [ "$silent" != "Y" ] ; then
  echo -n "Are you sure you wish to deploy $1 to $dbname ? (Y/N) "
  read ok
  if [ "$ok" != 'Y' -a "$ok" != "y" ] ; then
    exit
  fi
fi


# --------|   Work out some other stuff we'll need later   |--------

client=""
source=""
case "$dbname" in
  tlsavis_dev|tlsavis_stage|tlsavis_uat) client="AVI" ; source="branches" ;;
  tlsavis_prod)                          client="AVI" ; source="tags" ;;
  tlsgt_dev|tlsgt_stage|tlsgt_uat)       client="GTH" ; source="branches" ;;
  tlsgt_prod)                            client="GTH" ; source="tags" ;;
  ihg_dev|ihg_stage|tlsihgasp_uat)       client="IHG" ; source="branches" ;;
  tlsihg_prod)                           client="IHG" ; source="tags" ;;
  tlslor_dev|tlslor_stage|tlslor_uat)    client="LOR" ; source="branches" ;;
  tlslor_prod)                           client="LOR" ; source="tags" ;;
esac
if [ "$client" = "" ] ; then
  echo "Error - unable to identify client"
  exit 1
fi
if [ "$debug" = "Y" ] ; then
  echo "Client is $client" >> $log_detail
  echo "Source is $source" >> $log_detail
fi
now=`date +"%F %T"`
echo "$now - Deploying $1 to $dbname..." >> $log_summary
echo "$now - Deploying $1 to $dbname..." >> $log_detail


# --------|   Set SVN connection parameters   |--------

svn_url="https://svn.collinsontech.com/GMS/Projects/"
svn_username="TLS.Build"
svn_password="army-m3tro"


# --------|   SVN source i.e. trunk, branch or tag   |--------

if [ "$1" != "trunk" ] ; then
  svn_folder="$source/$1"
else
  svn_folder="$1"
fi


# --------|   SVN core and site roots   |--------

case "$client" in
  AVI)
    core_project="cts-loyalty-core/"
    site_project="gms-loyalty-sites/avis-europe/" ;;
  GTH)
    core_project="cts-loyalty-core/"
    site_project="gms-loyalty-sites/guoman-thistle/" ;;
  IHG)
    core_project="cts-ihg-core/"
    site_project="cts-ihg-sites/" ;;
  LOR)
    core_project="cts-loreal-core/"
    site_project="gms-loyalty-sites/loreal/" ;;
esac
svn_core_url=$svn_url$core_project$svn_folder
svn_site_url=$svn_url$site_project$svn_folder
if [ "$debug" = "Y" ] ; then
  echo "CORE path is $svn_core_url" >> $log_detail
  echo "SITE path is $svn_site_url" >> $log_detail
  echo "..."                        >> $log_detail
fi


# --------|   Source and target folders   |--------

# Each line contains three elements:
# 1. Source path in SVN
# 2. Shadow target path on server
# 3. Official target path on server
# The two target paths are required because there are several server folders
# which contain both core and site elements, and attempting to deploy both
# will simply result in one of the sets of elements being deleted... so instead
# files are pulled from SVN into "shadow" folders to avoid these conflicts,
# and then symbolic links are created in the "official" folders.

# SVN source path ................ Shadow target path ..................... Official target path

core_folders=$(cat <<EOF
CORE/ABF_Code                      $HOME/DatabaseObjects/ABF_Code           $HOME/DatabaseObjects/ABF_Code
CORE/Daemons/FHF/Daemon            $HOME/bin/fhf_daemon                     $HOME/bin
CORE/Daemons/FHF/Scripts           $HOME/bin/fhf_scripts                    $HOME/bin
CORE/DatabaseObjects/events        $HOME/DatabaseObjects/events/core        $HOME/DatabaseObjects/events
CORE/DatabaseObjects/indexes       $HOME/DatabaseObjects/indexes/core       $HOME/DatabaseObjects/indexes
CORE/DatabaseObjects/permits       $HOME/DatabaseObjects/permits/core       $HOME/DatabaseObjects/permits
CORE/DatabaseObjects/rules         $HOME/DatabaseObjects/rules/core         $HOME/DatabaseObjects/rules
CORE/DatabaseObjects/sequences     $HOME/DatabaseObjects/sequences/core     $HOME/DatabaseObjects/sequences
CORE/DatabaseObjects/tables        $HOME/DatabaseObjects/tables/core        $HOME/DatabaseObjects/tables
CORE/DatabaseObjects/tools         $HOME/bin/core/tools                     $HOME/bin
CORE/DatabaseObjects/views         $HOME/DatabaseObjects/views/core         $HOME/DatabaseObjects/views
CORE/DatabaseObjects/CORE_Data     $HOME/DatabaseObjects/CORE_Data          $HOME/DatabaseObjects/CORE_Data
CORE/DatabaseObjects/LOAD_Scripts  $HOME/DatabaseObjects/LOAD_Scripts/core  $HOME/DatabaseObjects/LOAD_Scripts
ReleaseScripts                     $HOME/ReleaseScripts/core                $HOME/ReleaseScripts
EOF)

site_folders=$(cat <<EOF
DatabaseObjects/events             $HOME/DatabaseObjects/events/site        $HOME/DatabaseObjects/events
DatabaseObjects/indexes            $HOME/DatabaseObjects/indexes/site       $HOME/DatabaseObjects/indexes
DatabaseObjects/permits            $HOME/DatabaseObjects/permits/site       $HOME/DatabaseObjects/permits
DatabaseObjects/rules              $HOME/DatabaseObjects/rules/site         $HOME/DatabaseObjects/rules
DatabaseObjects/sequences          $HOME/DatabaseObjects/sequences/site     $HOME/DatabaseObjects/sequences
DatabaseObjects/tables             $HOME/DatabaseObjects/tables/site        $HOME/DatabaseObjects/tables
DatabaseObjects/tools              $HOME/bin/site/tools                     $HOME/bin
DatabaseObjects/views              $HOME/DatabaseObjects/views/site         $HOME/DatabaseObjects/views
DatabaseObjects/LOAD_Scripts       $HOME/DatabaseObjects/LOAD_Scripts/site  $HOME/DatabaseObjects/LOAD_Scripts
DatabaseObjects/SITE_Data          $HOME/DatabaseObjects/SITE_Data          $HOME/DatabaseObjects/SITE_Data
ReleaseScripts                     $HOME/ReleaseScripts/site                $HOME/ReleaseScripts
EOF)


# --------|   Define function for creating links   |--------

function create_link {
  local source=$1
  local target=$2

  if [ "$debug" = "Y" ] ; then
    echo "Creating link from $source to $target..." >> $log_detail
  fi

  # If the source already exists and is not a link, remove it
  if [ -e "$source" -a ! -h "$source" ] ; then
    if [ "$debug" = "Y" ] ; then
      echo "rm -fr $source" >> $log_detail
    fi
    rm -fr "$source" >>$log_detail 2>&1
  fi

  # Make sure all sub-folders leading up to the source exist
  local source_name=`basename "$source"`
  local source_path=`echo "$source" | sed "s|/$source_name||g"`
  if [ ! -d "$source_path" ] ; then
    if [ "$debug" = "Y" ] ; then
      echo "mkdir $source_path" >> $log_detail
    fi
    mkdir -p "$source_path" >>$log_detail 2>&1
  fi

  # Create link if it doesn't already exist
  if [ ! -L "$source" ] ; then
    if [ "$debug" = "Y" ] ; then
      echo "ln -s $target $source" >> $log_detail
    fi
    ln -s "$target" "$source" >>$log_detail 2>&1
  fi
}


# --------|   Define function for processing these folder groups   |--------

# Bit of clunky logic here needed to process the array, which contains one
# element per "word" whether they are on the same line or not above, i.e.
# if the definition contains four sets of folders then the array will have
# twelve elements, so we need to loop through and process them in groups...

function process_folders {
  folder_array=$1
  first_command=$2
  second_command=$3

  # Verify that the folder arrays has a multiple of three items in it
  # so we don't risk doing anything if they have somehow become corrupted
  # (Don't ask why ${#folder_array[@]} doesn't give the array length...)
  count=0
  for item in ${folder_array[@]}
  do
    count=$(( $count + 1 ))
  done
  # Have we got a multiple of 3 items?
  if [ $(( $count % 3 )) -ne 0 ] ; then
    echo "Error - folder list contains an invalid number of entries"
    exit 1
  fi

  idx=1
  for item in ${folder_array[@]}
  do
    if [ $idx -eq 1 ] ; then
      this_source=$item
      idx=2
    elif [ $idx -eq 2 ] ; then
      this_interim=$item
      # Verify that interim folder is a sub-folder of home directory
      if [[ "$this_interim" != *"$HOME"* ]] ; then
        echo "Error - interim folder ($this_interim) is not a sub-folder of \$HOME"
        exit 1
      fi
      idx=3
    else
      this_target=$item
      # Verify that target folder is a sub-folder of home directory
      if [[ "$this_target" != *"$HOME"* ]] ; then
        echo "Error - target folder ($this_target) is not a sub-folder of \$HOME"
        exit 1
      fi
      
      # Now we've read all three elements, we can actually do some stuff...

      # Revert or remove target
      pwd=`pwd`
      if [ ! -d $this_interim ] ; then
        mkdir -p $this_interim
        if [ $? -ne 0 ] ; then
          echo "Error - unable to create interim folder ($this_interim)"
          exit 1
        fi
      fi
      cd $this_interim
      if [ $? -ne 0 ] ; then
        echo "Error - unable to cd to interim folder ($this_interim)"
        exit 1
      fi
      if [ "$debug" = "Y" ] ; then
        echo "$first_command $this_interim" >> $log_detail
      fi
      $first_command $this_interim >>$log_detail 2>&1
      cd $pwd

      # Switch or checkout target
      if [ "$debug" = "Y" ] ; then
        echo "$second_command$this_source $this_interim" >> $log_detail
      fi
      $second_command$this_source $this_interim >>$log_detail 2>&1

      # If the "shadow" and "official" targets are not the same then
      # we need to loop through all files in the shadow folder and create
      # symbolic links to these files from the official folder...
      if [ "$this_interim" != "$this_target" ] ; then
        if [ "$debug" = "Y" ] ; then
          echo "find $this_interim -type d -name .svn -prune -o -type f ! -name '.svn*' -print" >> $log_detail
        fi
        find $this_interim -type d -name .svn -prune -o -type f ! -name '.svn*' -print | while read filepath
        do
          # Get filename (and possibly path) below shadow folder
          filename=`echo $filepath | sed "s|$this_interim/||g"`
          # Create link to official folder
          create_link "$this_target/$filename" "$filepath"
        done
      fi
      idx=1
    fi
  done
}

# --------|   Work out whether to checkout or update   |--------

if [ -e "$HOME/DatabaseObjects/tables/core/.svn" ] ; then

  # SVN folders already exist, so do SVN update
  echo -n "Updating from SVN... "
  process_folders "${core_folders[@]}" "svn revert --recursive" "svn switch --username $svn_username --password $svn_password $svn_core_url/"
  process_folders "${site_folders[@]}" "svn revert --recursive" "svn switch --username $svn_username --password $svn_password $svn_site_url/"
  echo "Done"

else

  # No SVN folders exist, so do SVN checkout
  echo -n "Checking out from SVN... "
  process_folders "${core_folders[@]}" "rm -fr" "svn checkout --username $svn_username --password $svn_password $svn_core_url/"
  process_folders "${site_folders[@]}" "rm -fr" "svn checkout --username $svn_username --password $svn_password $svn_site_url/"
  echo "Done"

fi


# --------|   And we're done, round of applause, go home for tea   |--------

now=`date +"%F %T"`
echo "$now - Deploying $1 to $dbname... Done" >> $log_summary
echo " "                                      >> $log_summary
echo "$now - Deploying $1 to $dbname... Done" >> $log_detail
echo " "                                      >> $log_detail


# --------|   Ask the user if they want to see the log file   |--------


if [ "$silent" != "Y" ] ; then
  echo -n "Would you like to see the log file for this deployment ? (Y/N) "
  read ok
  if [ "$ok" = 'Y' -o "$ok" = "y" ] ; then
    view $log_detail
  fi
fi

