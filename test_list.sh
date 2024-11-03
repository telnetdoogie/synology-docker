#!/bin/bash

docker inspect jellyfin --format "{{.Name}} {{if index .Config.Labels \"com.docker.compose.project.config_files\"}}{{index .Config.Labels \"com.docker.compose.project.config_files\"}}{{else}}CONFIG NOT FOUND{{end}} {{.HostConfig.LogConfig.Type}}"
