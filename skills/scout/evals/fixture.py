import os
import sys
import json  # unused import

TIMEOUT = 30


def process_data(d):
    result = []
    for i in range(len(d)):
        if d[i] > 100:
            if d[i] < 1000:
                if d[i] % 2 == 0:
                    result.append(d[i] * 3.14159)  # magic value
    return result


def old_handler(x):
    # TODO: remove this after v2 migration (completed Q3 2024)
    pass


def getUserId():
    return 42


def get_user_name():
    return "test"
