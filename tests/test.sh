#!/bin/bash

set -ex

export COMPOSER_PROCESS_TIMEOUT=100000

touch /tmp/ci_status

exec 4</tmp/ci_status
flock 4

if [ "$(cat /tmp/ci_status)" != "done" ]; then
    apk add procps git unzip github-cli openssh

    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    mv composer.phar /usr/local/bin/composer

    php tests/jit.php

    composer update

    echo done > /tmp/ci_status
fi

exec 4<&-

if [ "$1" == "cs" ]; then
    composer psalm

    rmdir docs
    curl -L https://github.com/danog/MadelineProtoDocs/archive/refs/heads/master.tar.gz | tar -xz
    mv MadelineProtoDocs-master/ docs

    git submodule init schemas
    git submodule update schemas

    composer docs
    composer docs-fix
    composer cs-fix

    if [ "$(git diff)" != "" ]; then echo "Please run composer build!"; exit 1; fi

    exit 0
fi

if [ "$1" == "handshake" ]; then
    php tests/handshake.php
    exit 0
fi

if [ "$1" == "phpunit" ]; then
    composer test
    exit 0
fi

if [ "$1" == "phpunit-light" ]; then
    composer test-light
    exit 0
fi

echo "Unknown command!"

exit 1