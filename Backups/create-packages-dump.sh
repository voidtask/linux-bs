#!/bin/bash

# Permission check
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

original_dir=$(pwd)
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
temp_dir_name="package-dump-${timestamp}"
temp_dir="/my-pacman-dumps/${temp_dir_name}"

# Check if list.txt exists in original directory
if [ ! -f "${original_dir}/list.txt" ]; then
    echo "File list.txt does not exist in ${original_dir}. Exiting."
    exit 1
fi

mkdir -p "${temp_dir}"
echo "Created directory: ${temp_dir}"

# Change working directory to temp_dir
cd "${temp_dir}" || { echo "Failed to change directory to ${temp_dir}"; exit 1; }

cache_dir="$(pwd)/cache"
db_dir="$(pwd)/db"

if [ ! -d "${cache_dir}" ]; then
    mkdir "${cache_dir}"
    echo "Created directory: ${cache_dir}"
else
    echo "Directory cache already exists"
fi

if [ ! -d "${db_dir}" ]; then
    mkdir "${db_dir}"
    echo "Created directory: ${db_dir}"
else
    echo "Directory db already exists"
fi

# allow alpm to use the folder
sudo chown -R alpm:alpm ${temp_dir}

if ! sudo pacman --noconfirm -Syw --cachedir ${cache_dir} --dbpath ${db_dir} - < "${original_dir}/list.txt"; then
    echo "pacman command failed. Exiting."
    exit 1
fi

# Create custom pacman repository
cd cache || { echo "Failed to change directory to cache"; exit 1; }
sudo repo-add ./custom.db.tar.zst ./*.pkg.tar.zst
cd ..

# Create tar.gz archive
tar_filename="${temp_dir_name}.tar.gz"
tar -czvf "${original_dir}/${tar_filename}" cache db
echo "Created tar.gz archive: ${original_dir}/${tar_filename}"

# Create ISO file
iso_filename="${temp_dir_name}.iso"
if ! sudo mkisofs -o "${original_dir}/${iso_filename}" -R -J -joliet-long ${temp_dir}; then
    echo "Failed to make iso. Exiting."
    exit 1
fi

sudo chown "$USER":"$USER" "${original_dir}/${iso_filename}"
sudo chown "$USER":"$USER" "${original_dir}/${tar_filename}"

echo " "
echo "Done. Archives created:"
echo " - ${original_dir}/${tar_filename}"
echo " - ${original_dir}/${iso_filename}"
echo " "

