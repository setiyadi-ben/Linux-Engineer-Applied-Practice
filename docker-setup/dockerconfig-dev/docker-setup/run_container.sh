#!/bin/bash

docker build -t my_custom_image .

docker run -d \
  --name l-e-a-p_github_container \
  --net l-e-a-p_github_network \
  --ip 192.168.129.129 \
  l-e-a-p_github_docker_image
