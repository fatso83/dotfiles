#!/bin/bash

ps -elf --forest | grep -B5 '<[d]efunct>'
