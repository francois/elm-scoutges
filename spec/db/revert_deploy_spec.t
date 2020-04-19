#!/bin/sh
set -eu
echo '1..3'
sqitch --quiet revert --target test --plan-file db/sqitch-test.plan
echo 'ok 1 Revert test plan'
sqitch --quiet rebase --target test --plan-file db/sqitch.plan --verify
echo 'ok 2 Rebase production plan'
sqitch --quiet deploy --target test --plan-file db/sqitch-test.plan --verify
echo 'ok 3 Deploy test plan'
exit 0
