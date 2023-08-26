#!/usr/bin/env bash

nvim --headless --noplugin -u ./minimal_init.lua -c "PlenaryBustedFile tests/multicursors/insert_spec.lua { minimal_init = 'tests/minimal_init.lua' }"
nvim --headless --noplugin -u ./minimal_init.lua -c "PlenaryBustedFile tests/multicursors/normal_spec.lua { minimal_init = 'tests/minimal_init.lua' }"
nvim --headless --noplugin -u ./minimal_init.lua -c "PlenaryBustedFile tests/multicursors/search_spec.lua { minimal_init = 'tests/minimal_init.lua' }"
nvim --headless --noplugin -u ./minimal_init.lua -c "PlenaryBustedFile tests/multicursors/selections_spec.lua { minimal_init = 'tests/minimal_init.lua' }"
