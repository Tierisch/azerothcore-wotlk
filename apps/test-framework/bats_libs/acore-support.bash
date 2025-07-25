#!/usr/bin/env bash

# AzerothCore BATS Support Library
# Additional helper functions for BATS testing

# Load common test utilities
source "$(dirname "${BASH_SOURCE[0]}")/../helpers/test_common.sh"

# Standard setup for all AzerothCore tests
acore_test_setup() {
    setup_test_env
    create_acore_binaries
    create_acore_configs
}

# Standard teardown for all AzerothCore tests
acore_test_teardown() {
    cleanup_test_env
}

# Quick setup for startup script tests
startup_scripts_setup() {
    acore_test_setup
    create_test_script_config "test" "test-server"
    
    # Create additional test binary for startup scripts
    create_test_binary "test-server" 0 2 "Test server starting with config:"
    
    # Create the test-server.conf file that tests expect
    cat > "$TEST_DIR/test-server.conf" << EOF
# Test server configuration file
# Generated by AzerothCore test framework
Database.Info = "127.0.0.1;3306;acore;acore;acore_world"
LoginDatabaseInfo = "127.0.0.1;3306;acore;acore;acore_auth"
CharacterDatabaseInfo = "127.0.0.1;3306;acore;acore;acore_characters"
EOF
}

# Quick setup for compiler tests
compiler_setup() {
    acore_test_setup
    
    # Create mock build tools
    create_test_binary "gcc" 0 1
    create_test_binary "g++" 0 1
    create_test_binary "ninja" 0 2
    
    # Create mock CMake files
    mkdir -p "$TEST_DIR/build"
    touch "$TEST_DIR/build/CMakeCache.txt"
    echo "CMAKE_BUILD_TYPE:STRING=RelWithDebInfo" > "$TEST_DIR/build/CMakeCache.txt"
}

# Quick setup for docker tests
docker_setup() {
    acore_test_setup
    
    # Create mock docker commands
    create_test_binary "docker" 0 1 "Docker container started"
    create_test_binary "docker-compose" 0 2 "Docker Compose services started"
    
    # Create test docker files
    cat > "$TEST_DIR/Dockerfile" << 'EOF'
FROM ubuntu:20.04
RUN apt-get update
EOF
    
    cat > "$TEST_DIR/docker-compose.yml" << 'EOF'
version: '3.8'
services:
  test-service:
    image: ubuntu:20.04
EOF
}

# Quick setup for extractor tests
extractor_setup() {
    acore_test_setup
    
    # Create mock client data directories
    mkdir -p "$TEST_DIR/client"/{Maps,vmaps,mmaps,dbc}
    
    # Create some test data files
    echo "Test map data" > "$TEST_DIR/client/Maps/test.map"
    echo "Test DBC data" > "$TEST_DIR/client/dbc/test.dbc"
}

# Helper to run command with timeout and capture output
run_with_timeout() {
    local timeout_duration="$1"
    shift
    run timeout "$timeout_duration" "$@"
}

# Helper to check if a process is running
process_running() {
    local process_name="$1"
    pgrep -f "$process_name" >/dev/null 2>&1
}

# Helper to wait for a condition
wait_for_condition() {
    local condition="$1"
    local timeout="${2:-10}"
    local interval="${3:-1}"
    
    local count=0
    while ! eval "$condition"; do
        sleep "$interval"
        count=$((count + interval))
        if [[ $count -ge $timeout ]]; then
            return 1
        fi
    done
    return 0
}
