#!/bin/bash
set -o pipefail

NUM_GPUS=${NUM_GPUS:-1}
BATCH_SIZE=${BATCH_SIZE:-32}
NUM_EPOCHS=${NUM_EPOCHS:-2}

RESULTS_DIR=${RESULTS_DIR:-/tmp/results}
mkdir -p "$RESULTS_DIR"

MODELS=("$@")

echo "--- START" | tee "$RESULTS_DIR/e2e.log"

status=0
success=0
fail=0

for t in "${MODELS[@]}";
do
  echo "--- START $t" | tee -a "$RESULTS_DIR/e2e.log"

  python3 \
    -m tf_cnn_benchmarks \
    --model="$t" \
    --batch_size="$BATCH_SIZE" \
    --num_gpus="$NUM_GPUS" \
    --num_epochs="$NUM_EPOCHS" \
    |& tee -a "$RESULTS_DIR/e2e.log"

  if [ $? != 0 ]
  then
    echo "--- FAILED $t" | tee -a "$RESULTS_DIR/e2e.log"
    status=1
    fail=$((fail+1))
  else
    echo "--- PASSED $t" | tee -a "$RESULTS_DIR/e2e.log"
    success=$((success+1))
  fi
done

echo "SUCCESS! -- $success Passed | $fail Failed |" | tee -a "$RESULTS_DIR/e2e.log"

cd "$RESULTS_DIR"
tar -czf results.tar.gz ./*

echo -n "${RESULTS_DIR}/results.tar.gz" > "${RESULTS_DIR}/done"
exit $status
