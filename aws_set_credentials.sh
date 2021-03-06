#!/bin/bash

# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# Creates AWS credentials from an accessKeys.csv file.

# Check arguments for existing accessKeys.csv file.
# arguments: named_key_csv_file
function checkArgs () {
  local FILE_ARG='<path to csv accessKeys file>'

  if [ -z "$1" ]; then
    echo 'Error: missing argument.'
    echo "$0 ${FILE_ARG}"
    exit 1
  fi

  if [ "$1" != "exists" ] && [ ! -e "$1" ]; then
    echo 'Error: file not found.'
    echo "$0 ${FILE_ARG}"
    exit 1
  fi
}


# Backup existing - if credentials.bak exists fail.
# arguments: source_credentials_file target_file_path
function backupCredentials() {
  if [ -e $1.bak ]; then
    echo "Error: backup creds found already. $1.bak"
    echo "(Remove $1 file to retry.)"
    exit 1
  fi

  if [ -e $1 ]; then
    cp "$1" "$1.bak"
    echo "Created backup ($1.bak)."
  fi
}


# Start the new file with [default]
# arguments: credentials_file
function addDefault() {
  echo '[default]' > $1
}


# Add AWS secrets.
# arguments: source_keys_file credentials_file
function addSecrets() {
  local KEY_ID=$(tail -1 "$1" | cut -d"," -f1)
  local SECRET_KEY=$(tail -1 "$1" | cut -d"," -f2)

  echo "aws_access_key_id=${KEY_ID}" >> $2
  echo "aws_secret_access_key=${SECRET_KEY}" >> $2

  echo "Created $2."
}


# Start a new terraform.tfvars file.
# arguments: full_path_file_name.
function createTFVars() {
  if [ ! -e $1 ]; then
    echo "/*" > $1
    echo " * Initialized Terraform variables." >> $1
    echo " */" >> $1
  fi
}


# If not already present, add a key-value to tfvars file.
# arguments: tfvars_path_file_name key value
function addTFVar() {
  if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo 'Error: missing argument for addTFVar().'
    exit 1
  fi

  local VAR_NAME="$2"
  local KEY_EXISTS="$(cat $1 | grep $2)"

  if [ -z "${KEY_EXISTS}" ]; then
    echo "" >> $1
    echo "$2 = \"$3\"" >> $1
    echo "Updated $2 in $1."
  fi
}


# Create fresh AWS credentials file.
# arguments: named_key_csv_file
function createCredentials () {
  # ~ only expands when NOT quoted (below).
  local CREDS_FILE_DIR=~/.aws
  local CREDS_FILE_PATH="${CREDS_FILE_DIR}/credentials_autonetdeploy"
  local THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  local TFVARS_DIR_PATH="${THIS_DIR}/terraform"
  local TFVARS_FILE_PATH="${TFVARS_DIR_PATH}/terraform.tfvars"
  local TFVAR_CREDS='aws_credentials_file_path'

  if [ "$1" != "exists" ]; then
    mkdir -p ${CREDS_FILE_DIR}
    backupCredentials ${CREDS_FILE_PATH}
    addDefault ${CREDS_FILE_PATH}
    addSecrets $1 ${CREDS_FILE_PATH}
  fi

  createTFVars "${TFVARS_FILE_PATH}"
  addTFVar "${TFVARS_FILE_PATH}" "${TFVAR_CREDS}" "${CREDS_FILE_PATH}"
}


checkArgs $1
# Pass "exists" to skip credential file copying.
createCredentials $1
