#!/bin/bash

JS_CHANGES=`git diff --name-only --diff-filter=ACM HEAD^ | grep '\.js'`

echo 'JS_CHANGES='$JS_CHANGES

if [[ $JS_CHANGES ]]
then
    echo $JS_CHANGES | xargs npx eslint -c test/eslint/.eslintrc.yml
fi
