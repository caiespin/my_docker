FROM ros:humble

# Installing programs
RUN apt-get update \
    && apt-get install -y \
    nano \
    vim \
    ros-humble-desktop \
    ros-humble-v4l2-camera \
    ros-humble-realsense2-camera \
    ros-humble-realsense2-description \
    python3-vcstool \
    x11-apps \
    gedit \
    terminator \
    jstest-gtk \
    python3-serial \
    python3-colcon-common-extensions \
    git \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && mkdir /home/$USERNAME/.config && chown $USER_UID:$USER_GID /home/$USERNAME/.config

# Adding user to the dialout group to interface with serial devices
RUN usermod -aG dialout ${USERNAME}
RUN usermod -aG video ${USERNAME}

# Set up sudo
RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  && rm -rf /var/lib/apt/lists/*

# Copy the entrypoint and bashrc scripts so we have 
# our container's environment set up correctly
COPY my_entrypoint.sh /my_entrypoint.sh
COPY bashrc /home/${USERNAME}/.bashrc
RUN chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

# Create a workspace folder inside the container 
USER $USERNAME
WORKDIR /home/$USERNAME
RUN mkdir -p /home/$USERNAME/ld06_ws/src

# Clone the LD06 repository into the workspace
RUN git clone --depth 1 https://github.com/caiespin/ldlidar_stl_ros2 \
    /home/$USERNAME/ld06_ws/src/ldlidar_stl_ros2

# Build the workspace
# Note: We need to source ROS in the same shell before building.
SHELL ["/bin/bash", "-c"]
RUN source /opt/ros/humble/setup.bash \
    && cd /home/$USERNAME/ld06_ws \
    && colcon build

# Make sure new packages are sourced automatically
RUN echo "source /home/$USERNAME/ld06_ws/install/setup.bash" >> /home/$USERNAME/.bashrc

# Set up entrypoint and default command
ENTRYPOINT ["/bin/bash", "/my_entrypoint.sh"]
CMD ["bash"]