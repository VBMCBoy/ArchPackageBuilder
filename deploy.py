#!/bin/env python3

import os
import requests
import subprocess
import sys

git_pass = os.environ['GIT_PASS']
pull_id = os.environ['MERGE_ID']
ssh_key = os.environ['SSH_KEY']
project_id = 1
reviewer_id = 1
pull_endpoint = f"https://git.aurum.lan/api/pull-requests/{pull_id}"

with open(os.path.expanduser('/root/ssh/id_ed25519'), 'w') as keyfile:
    keyfile.write(ssh_key)
os.chmod(os.path.expanduser('/root/ssh/id_ed25519'), 0o600)

r = requests.get(pull_endpoint, auth=('kay', git_pass))
project = r.json()['sourceBranch']

print(f'Deploying `{project}`...')

subprocess.run(['pwd'])
subprocess.run(['ls', '-lAh'])

subprocess.run(['mkdir', 'tmp'])
os.chdir('tmp')
subprocess.run(['rsync', '-a', '--delete', 'root@10.0.0.102:/srv/packages/custom', '.'])
subprocess.run(['pwd'])
subprocess.run(['ls', '-lAh'])

subprocess.run(['repo-add', '--remove', f'../{project}/*.pkg.tar.zst'])
subprocess.run(['pwd'])
subprocess.run(['ls', '-lAh'])

subprocess.run(['rsync', '-a', '--delete', '.', 'root@10.0.0.102:/srv/packages/custom'])
subprocess.run(['pwd'])
subprocess.run(['ls', '-lAh'])
