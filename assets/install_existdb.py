#!/usr/bin/env python
from __future__ import absolute_import
from __future__ import print_function
from __future__ import unicode_literals

import sys
import os
from subprocess import *
import time

print('-' * 80)
print('Welcome to the eXist-db installer!')
print('-' * 80)

def read_n_print(p, expected):
    """Careful: this could run indefinitely!"""
    while True:
        output = p.stdout.readline()
        print(output, end='')
        sys.stdout.flush()
    
        if output.strip() == expected:    
            break


def writeln(p, msg):
    print('>>>', msg)
    p.stdin.write(msg + '\n')    
    sys.stdout.flush()

dirname = os.path.dirname(sys.argv[0])
print("Changing directory to '{}'".format(dirname))
sys.stdout.flush()
os.chdir(dirname)

print("Starting installer ...")

if not os.path.exists('/usr/bin/java'):
    raise Exception('Java not found! Bailing out!')
    
p = Popen(
    '/usr/bin/java -jar eXist-db-setup-2.2-rev0000.jar',
    stdin=PIPE, stdout=PIPE, stderr=PIPE,
    shell=True
)

prompts = [
    ('Select target path [{}]'.format(dirname), '/usr/local/exist_atp_2.2'),
    ('press 1 to continue, 2 to quit, 3 to redisplay', '1'),
    ('Data dir:  [webapp/WEB-INF/data]', 'webapp/WEB-INF/data'),
    ('press 1 to continue, 2 to quit, 3 to redisplay', '1'),
    ('Enter password:  []', 'password'),
    ('Enter password:  [password]', ''),
    ('Maximum memory in mb: [1024]', '1024'),
    ('Cache memory in mb: [128]', '128'),
    ('press 1 to continue, 2 to quit, 3 to redisplay', '1'),
]

for prompt in prompts:
    read_n_print(p, expected=prompt[0])
    writeln(p, prompt[1])

stdout, stderr = p.communicate()
print('-' * 80)
print(stdout)
print('-' * 80)
print(stderr)
