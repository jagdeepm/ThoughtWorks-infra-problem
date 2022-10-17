#!/bin/bash

#-----------------------------------------
# Static WebServe Initialization Script
#-----------------------------------------

if [ ${UID} -gt 0 ] && [ ${GID} -gt 0 ]; then
  id apprunner &>/dev/null
  if [ $? -eq 1 ]; then
    groupadd -g ${GID} apprunner
    useradd -u ${UID} -g ${GID} -ms /bin/bash apprunner
  fi

fi

if [ ${UID} -gt 0 ] && [ ${GID} -gt 0 ]; then
  su apprunner -c 'python -u /usr/src/app/front-end/public/serve.py'
else
  python -u /usr/src/app/front-end/public/serve.py
fi
