#!/bin/bash

# Default values
backup_type="full"
source_directories=("/var/backup")
local_destination="/var/backup"
remote_user="root"
remote_ip="10.10.135.210"
debug_mode=false
dateandtime=$(date '+%Y%m%d-%H%M%S')
ssh_check_command="[ ! -d \"$source_directories\" ]"

# Function to display help
display_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -t, --type TYPE            Backup type: full or inc (default: $backup_type)"
  echo "  -s, --source DIR           Remote source directory (can be specified multiple times)"
  echo "  -d, --destination DIR      Local destination directory (default: $local_destination)"
  echo "  -u, --user USER            Remote user (default: $remote_user)"
  echo "  -i, --ip IP                Remote server IP (default: $remote_ip)"
  echo "  -D, --debug                Enable debug mode"
  echo "  -h, --help                 Display this help message"
  exit 1
}

# Parsing command line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--type)
      case "$2" in
        full|inc)
          backup_type="$2"
          shift 2
          ;;
        *)
          echo "Invalid backup type: $2. Please use 'full' or 'inc'."
          exit 1
          ;;
      esac
      ;;
    -s|--source)
      source_directories+=("$2")
      shift 2
      ;;
    -d|--destination)
      local_destination="$2"
      shift 2
      ;;
    -u|--user)
      remote_user="$2"
      shift 2
      ;;
    -i|--ip)
      remote_ip="$2"
      shift 2
      ;;
    -D|--debug)
      debug_mode=true
      shift
      ;;
    -h|--help)
      display_help
      ;;
    *)
      echo "Invalid option: $1"
      display_help
      ;;
  esac
done

# Debug mode
if [ "$debug_mode" = true ]; then
  set -x
fi

# Check if the remote directory exists and stop the script if it doesn't
if ssh "$remote_user@$remote_ip" "$ssh_check_command"; then
  echo "The remote directory does not exist. Stopping the script."
  exit 1
fi

# Performng full or incremental backup download
if [ "$backup_type" = "full" ]; then
  for source_dir in "${source_directories[@]}"; do
    rsync -avz --mkpath -e "ssh" "$remote_user@$remote_ip:$source_dir/" "$local_destination/full/full-$dateandtime"
  done
elif [ "$backup_type" = "inc" ]; then
  for source_dir in "${source_directories[@]}"; do
    rsync -avz --mkpath -e "ssh" "$remote_user@$remote_ip:$source_dir/" "$local_destination/inc/incremental-$dateandtime/"
  done
else
  echo "Invalid backup type: $backup_type"
  display_help
fi

echo "Backup download completed successfully"

# Number of backups to keep in "full" and "inc" directories
num_backups_to_keep=1

# Destination directories for old backups
full_old_destination="$local_destination/fullOld/"
inc_old_destination="$local_destination/incOld/"

# Function to create a directory if it doesn't exist
create_directory_if_not_exists() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

# Creating the "fullOld" and "incOld" directories if they do not exist
create_directory_if_not_exists "$full_old_destination"
create_directory_if_not_exists "$inc_old_destination"

# Function to archive and compress directories
archive_and_compress_directory() {
  local source_dir="$1"
  local destination_dir="$2"
  local archive_name="$3"

  if [ -d "$source_dir" ]; then
    create_directory_if_not_exists "$destination_dir"
    tar -czf "$destination_dir/$archive_name.tar.gz" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
  fi
}

# Check $backup_type and trigger archiving based on the type
if [ "$backup_type" = "full" ]; then
  # Archive and compress all but the latest directories in local_destination/full
  full_backup_dirs=($(ls -dt "$local_destination/full"/*))
  latest_full_dir="${full_backup_dirs[0]}/"

  for full_dir in "${full_backup_dirs[@]:1}"; do
    archive_and_compress_directory "$full_dir" "$full_old_destination" "$(basename "$full_dir")"
    rm -rf "$full_dir"
  done
elif [ "$backup_type" = "inc" ]; then

  # Archive and compress all but the latest directories in local_destination/inc/
  inc_backup_dirs=($(ls -dt "$local_destination/inc"/*))
  latest_inc_dir="${inc_backup_dirs[0]}/"

  for inc_dir in "${inc_backup_dirs[@]:1}"; do
    archive_and_compress_directory "$inc_dir" "$inc_old_destination" "$(basename "$inc_dir")"
    rm -rf "$inc_dir"
  done
fi


# Logrotate

# Add logrotate configuration for backup_bloomex if it doesn't exist
logrotate_config="/etc/logrotate.d/bloomex_backup"

if [ ! -f "$logrotate_config" ]; then
  echo -e "$full_old_destination*.gz\n$inc_old_destination*.gz {
    weekly
    rotate 3
    missingok
    notifempty
    nocompress
  }" | sudo tee "$logrotate_config"
fi

# Force run logrotate
if logrotate -f "$logrotate_config"; then
  echo "success"
else
  echo "Log rotation error"
fi


