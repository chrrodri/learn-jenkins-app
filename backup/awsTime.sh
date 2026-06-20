#!/bin/bash

export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
sudo hwclock -s
sudo service ntpsec restart
alias tf="terraform"

