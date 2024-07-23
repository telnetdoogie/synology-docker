#!/bin/bash

# Store container information in an array
containers_info=()

# Get the list of containers and their compose locations
for c in $(docker ps -q); do
    container_info=$(docker inspect "$c" --format '{{.Name}} {{if index .Config.Labels "com.docker.compose.project.config_files"}}{{index .Config.Labels "com.docker.compose.project.config_files"}}{{else}}!---not_managed_by_compose---!{{end}}')
    containers_info+=("$container_info")
done

# Sort the array based on the second field (compose location)
IFS=$'\n' sorted_containers_info=($(printf "%s\n" "${containers_info[@]}" | sort -u -t " " -k 2))

# Calculate the maximum length for the container names and compose locations
max_container_length=0
max_location_length=0
for info in "${sorted_containers_info[@]}"; do
    container=$(echo "$info" | awk '{print $1}')
    location=$(echo "$info" | awk '{print $2}')
    [ ${#container} -gt $max_container_length ] && max_container_length=${#container}
    [ ${#location} -gt $max_location_length ] && max_location_length=${#location}
done

# Print the header
printf "%-${max_container_length}s  %s\n" "Container" "Compose_Location"
printf "%-${max_container_length}s  %s\n" "$(printf '%*s' "${max_container_length}" | tr ' ' '-')" "$(printf '%*s' "${max_location_length}" | tr ' ' '-')"

# Print the sorted container information
for info in "${sorted_containers_info[@]}"; do
    container=$(echo "$info" | awk '{print $1}')
    location=$(echo "$info" | sed -e 's/^[^ ]* //')
    printf "%-${max_container_length}s  %s\n" "$container" "$location"
done

