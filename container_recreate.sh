#!/bin/bash

# Check if a container ID or name was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <container_name_or_id>"
  exit 1
fi

# Get container details using docker inspect
container_id=$1
container_info=$(docker inspect "$container_id")

# Initialize an empty array for the docker command
docker_command=()

# Extract the container name
container_name=$(echo "$container_info" | jq -r '.[0].Name' | sed 's/\///')

# Extract the image name
image=$(echo "$container_info" | jq -r '.[0].Config.Image')

# Extract host environment variables
host_env=$(printenv | awk -F= '{print $1}' | sort)

# Extract container environment variables and filter out those present on the host
env_vars=$(echo "$container_info" | jq -r '.[0].Config.Env[]' | awk -F= '{print $1}' | sort)
filtered_env_vars=$(comm -23 <(echo "$env_vars") <(echo "$host_env"))

# Add base docker command to the array
docker_command+=("docker run -d \\")
docker_command+=("--name $container_name")

# Format the remaining environment variables for docker run
for var in $filtered_env_vars; do
  value=$(echo "$container_info" | jq -r --arg var "$var" '.[0].Config.Env[] | select(startswith($var))')
  if [ -n "$value" ]; then
    docker_command+=("-e \"$value\"")
  fi
done

# Extract port mappings and add each port to the array individually
ports=$(echo "$container_info" | jq -r '.[0].HostConfig.PortBindings | to_entries[]? | "-p " + .value[0].HostPort + ":" + .key')
if [ -n "$ports" ]; then
  # Add each port as a separate entry
  while IFS= read -r port; do
    docker_command+=("$port")
  done <<< "$ports"
fi

# Extract volumes and add each volume to the array individually
volumes=$(echo "$container_info" | jq -r '.[0].Mounts[]? | "-v " + .Source + ":" + .Destination')
if [ -n "$volumes" ]; then
  # Add each volume as a separate entry
  while IFS= read -r volume; do
    docker_command+=("$volume")
  done <<< "$volumes"
fi

# Extract the command used inside the container
cmd=$(echo "$container_info" | jq -r '.[0].Config.Cmd | join(" ")')

# Add the image and command
docker_command+=("-it $image $cmd")

# Output the final docker command with a backslash at the end of each line except the last
echo "${docker_command[0]}"
for ((i = 1; i < ${#docker_command[@]}; i++)); do
  if [ $i -lt $((${#docker_command[@]} - 1)) ]; then
    echo "    ${docker_command[$i]} \\"
  else
    echo "    ${docker_command[$i]}"
  fi
done

