#!/usr/bin/env bash

nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedFile tests/multicursors/insert_spec.lua"
nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedFile tests/multicursors/normal_spec.lua"
nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedFile tests/multicursors/search_spec.lua"
nvim --headless --noplugin -u tests/minimal_init.lua -c "PlenaryBustedFile tests/multicursors/selections_spec.lua"
