#!/bin/sh
set -e

ls $WORKDIR/.git > /dev/null && cd $WORKDIR || cd /app
echo working from `pwd`
echo OS-API DB: $OS_API_ENGINE

if [ ! -z "$GIT_REPO" ]; then
    rm -rf /remote || true && git clone $GIT_REPO /remote && cd /remote;
    if [ ! -z "$GIT_BRANCH" ]; then
        git checkout origin/$GIT_BRANCH
    fi
    pip install -U -r requirements.txt
else
    (cd /repos/babbage.fiscal-data-package && pip3 install -U -e . && echo using `pwd` dev version) || true
    (cd /repos/babbage && pip3 install -U -e . && echo using `pwd` dev version) || true
    (cd /repos/datapackage-py && pip3 install -U -e . && echo using `pwd` dev version) || true
    (cd /repos/tabulator-py && pip3 install -U -e . && echo using `pwd` dev version) || true
    (cd /repos/jsontableschema-py && pip3 install -U -e . && echo using `pwd` dev version) || true
    (cd /repos/jsontableschema-sql-py && pip3 install -U -e . && echo using `pwd` dev version) || true
fi

python3 --version
if [ ! -z "$OS_API_LOADER" ]; then
    FISCAL_PACKAGE_ENGINE=$OS_API_ENGINE bb-fdp-cli create-tables && echo "CREATED TABLES"
    python3 -m celery --concurrency=4 -A babbage_fiscal.tasks -l INFO worker &
fi
gunicorn -t 120 -w 4 os_api.app:app -b 0.0.0.0:8000
