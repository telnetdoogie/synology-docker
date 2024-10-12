#!/bin/bash

# Check if a container ID or name was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <container_name_or_id>"
  exit 1
fi

# Get container details using docker inspect
container_id=$1
container_info=$(docker inspect "$container_id")

# Extract the container name
container_name=$(echo "$container_info" | jq -r '.[0].Name' | sed 's/\///')

# Extract the image name
image=$(echo "$container_info" | jq -r '.[0].Config.Image')

# Extract host environment variables
host_env=$(printenv | awk -F= '{print $1}' | sort)

# Extract container environment variables and filter out those present on the host
env_vars=$(echo "$container_info" | jq -r '.[0].Config.Env[]' | awk -F= '{print $1}' | sort)
filtered_env_vars=$(comm -23 <(echo "$env_vars") <(echo "$host_env"))

# Format the remaining environment variables for docker run
env_options=$(for var in $filtered_env_vars; do
  value=$(echo "$container_info" | jq -r --arg var "$var" '.[0].Config.Env[] | select(startswith($var))')
  echo "    -e \"$value\" \\"
done)

# Extract port mappings
ports=$(echo "$container_info" | jq -r '.[0].HostConfig.PortBindings | to_entries[] | "    -p " + .value[0].HostPort + ":" + .key + " \\"')

# Extract volumes
volumes=$(echo "$container_info" | jq -r '.[0].Mounts[] | "    -v " + .Source + ":" + .Destination + " \\"')

# Extract the command used inside the container
cmd=$(echo "$container_info" | jq -r '.[0].Config.Cmd | join(" ")')

# Generate the docker run command conditionally, excluding empty sections
docker_command="docker run -d \\
    --name $container_name \\"

# Add env_options if not empty
if [ -n "$env_options" ]; then
  docker_command+="$env_options"
fi

# Add ports if not empty
if [ -n "$ports" ]; then
  docker_command+="$ports"
fi

# Add volumes if not empty
if [ -n "$volumes" ]; then
  docker_command+="$volumes"
fi

# Add image and command
docker_command+="    $image $cmd"

# Remove any double (or more) whitespaces
cleaned_command=$(echo "$docker_command" | sed 's/  */ /g' | sed 's/\\/\\\n/g') 

# Print the cleaned docker run command
echo "$cleaned_command"

