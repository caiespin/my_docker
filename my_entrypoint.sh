#!/bin/bash

set -e 

# Source the ROS setup
source /opt/ros/humble/setup.bash

# Source your workspace
source /home/ros/ld06_ws/install/setup.bash

cd ~

echo "Provided arguments: $@"

exec $@