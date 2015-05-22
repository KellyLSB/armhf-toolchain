#!/bin/bash

function getVars() {   grep -Eo '\{\{[A-Z_]+\}\}' $1 | sort -u;   }
function getVal()  { eval "echo \$$(grep -Eo '[A-Z_]+' <<<"$1")"; }
function sedCmd()  {            echo "-e 's|$1|$2|g'";            }

function parse()   {
	local sed_cmd=()
  local var val

	for var in $(getVars $1); do
		val="$(getVal $var)"

		if [[ -n $val ]]; then
			sed_cmd+=("$(sedCmd $var "$val")")
		fi
	done

	if [[ -n $sed_cmd ]]; then
		echo "sed ${sed_cmd[@]} $1 > $2"
		eval "sed ${sed_cmd[@]} $1 > $2"
  else
    echo "Nothing to render... copying instead."
    cp -v $1 $2
	fi

	sed_cmd= ; var= ; val= ;
  unset sed_cmd var val
}

parse $1 $2
