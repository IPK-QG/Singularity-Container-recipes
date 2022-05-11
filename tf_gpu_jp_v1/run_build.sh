#!/bin/bash
set -ue

# set variables
thisdir="$(dirname "${BASH_SOURCE[0]}")"
ADDRESS="127.0.0.1"
port=8888
CONTAINER="$thisdir/Singularity_gpu_v2.sif" # you may specify a different container name.
ins="ins_jup_$port"

if [[ ! -d "$thisdir/jupyter" ]]
then
  mkdir "$thisdir/jupyter"
fi

if [[ ! -d "$thisdir/jupyter/runtime" ]]
then
  mkdir "$thisdir/jupyter/runtime"
fi

start(){
  singularity instance start --nv \
	-W "/proj/" \
	-H "$thisdir:/proj/" \
	-B "$thisdir/jupyter:/usr/share/jupyter" \
	"$CONTAINER" "$ins"

  (singularity exec instance://"$ins" jupyter lab \
  --ip=127.0.0.1 \
  --port="$port" \
  --ServerApp.root_dir=/proj/ > "$thisdir/jupyter/jupyter.log" 2> "$thisdir/jupyter/jupyter.err") &

  pid=$!
  disown "$pid"
  
  if [[ -f  "$thisdir/jupyter/pid.info" ]]
  then
    rm -f  "$thisdir/jupyter/pid.info"
    touch  "$thisdir/jupyter/pid.info"
  else
    touch  "$thisdir/jupyter/pid.info"
  fi
  
  echo "$ins" > "$thisdir/jupyter/pid.info"
  
  echo "Acess the jupyter instance at $ADDRESS:$port"
}

stop(){
  ins_in=$(cat "$thisdir/jupyter/pid.info")
  singularity instance stop "$ins_in"
}

if [ "$#" = 0 ]; then
  echo ""
  echo "Please give one of the following available commands: "
  echo "  start, stop"
  echo ""
  exit 1
else
  cmd="$1"
  shift
fi

case $cmd in 
  start) start "$@"
  ;;
  stop) stop "$@"
  ;;
esac
