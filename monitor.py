#!/usr/bin/env python3
import curses
import sys, os
import time

import platform
# import os, platform, subprocess
def get_processor_name():
    return "Apple M1"
    if platform.system() == "Darwin":
        # os.environ['PATH'] = os.environ['PATH'] + os.pathsep + '/usr/sbin'
        command ="/usr/sbin/sysctl -n machdep.cpu.brand_string"
        return subprocess.check_output(command).strip()
    return ""

def get_OS_ver():
    ver = platform.mac_ver();
    return f'macOS {ver[0]} ({ver[2]})'

log_flag = False;
if log_flag:
    log_file = open("message.log","w")

def get_sorted_names():
    # get `name1, name2, name3,` as names_str
    names_str = sys.stdin.readline().strip()
    names = names_str.split(',')[:-1] # ignore last '' item
    names = [name.strip() for name in names]
    name_i = [(name, i) for i, name in enumerate(names)]

    # alphabetical order
    sorted_name_i = sorted(name_i, key=lambda x: x[0].lower())
    sorted_names = [name for name, i in sorted_name_i]
    sorted_names = [name.replace('Sensor','#') for name in sorted_names]

    ordered_list = [i for name, i in sorted_name_i]
    # i-th place holds nums[ordered_list[i]]

    if log_flag:
        print(names_str, '\n', sep='\n', file=log_file, flush=True) # sorted_name_i
    return sorted_names, ordered_list

def get_sorted_nums(ordered_list):
    nums_str = sys.stdin.readline().strip()
    nums = nums_str.split(',')[:-1]
    nums = [num.strip() for num in nums]
    assert len(nums) == len(ordered_list)

    sorted_nums = [float(nums[ordered_list[i]]) for i in range(len(nums))]
    if log_flag:
        print(nums_str, '\n', sep='\n', file=log_file, flush=True) # sorted_nums
    return sorted_nums

def main(stdscr):
    curses.start_color()
    curses.use_default_colors()
    # 57 items, max name len = 25
    # sorted_names = ['ANE MTR Temp Sensor1', 'GPU MTR Temp Sensor1', 'GPU MTR Temp Sensor4', 'ISP MTR Temp Sensor5', 'NAND CH0 temp', 'PMGR SOC Die Temp Sensor0', 'PMGR SOC Die Temp Sensor1', 'PMGR SOC Die Temp Sensor2', 'PMU TP3w', 'PMU tcal', 'PMU tdev1', 'PMU tdev2', 'PMU tdev3', 'PMU tdev4', 'PMU tdev5', 'PMU tdev6', 'PMU tdev7', 'PMU tdev8', 'PMU tdie1', 'PMU tdie2', 'PMU tdie4', 'PMU tdie5', 'PMU tdie6', 'PMU tdie7', 'PMU tdie8', 'PMU2 TR0Z', 'PMU2 TR1d', 'PMU2 TR1l', 'PMU2 TR2d', 'PMU2 TR2l', 'PMU2 TR3b', 'PMU2 TR3d', 'PMU2 TR4b', 'PMU2 TR4d', 'PMU2 TR5b', 'PMU2 TR5d', 'PMU2 TR6b', 'PMU2 TR7b', 'PMU2 TR8b', 'SOC MTR Temp Sensor0', 'SOC MTR Temp Sensor1', 'SOC MTR Temp Sensor2', 'eACC MTR Temp Sensor0', 'eACC MTR Temp Sensor3', 'gas gauge battery', 'gas gauge battery', 'gas gauge battery', 'gas gauge battery', 'gas gauge battery', 'gas gauge battery', 'pACC MTR Temp Sensor2', 'pACC MTR Temp Sensor3', 'pACC MTR Temp Sensor4', 'pACC MTR Temp Sensor5', 'pACC MTR Temp Sensor7', 'pACC MTR Temp Sensor8', 'pACC MTR Temp Sensor9'];

    sorted_names, ordered_list = get_sorted_names()
    n = len(sorted_names)
    max_name_length = max(map(len, sorted_names));

    ncol = 2
    nrow0 = 3
    nrow1 = n//2 + 1

    sys_info = f'{get_processor_name()}, {get_OS_ver()}' # Processor: , OS:

    max_nums = None

    while True:
        # Clear screen
        stdscr.clear()
        ny,nx = stdscr.getmaxyx()
        # Coordinates are always passed in the order y,x
        # the top-left corner of a window is coordinate (0,0).
        # assert nx>=80 and ny>=34
        if not (nx>=80 and ny>=34):
            stdscr.addnstr(0,0, 'enlarge the size of this terminal...', 50, curses.A_REVERSE)
            stdscr.addnstr(1,0, f'requires min 32x80, now {ny}x{nx} (row x col)', 50)
            stdscr.refresh()
            time.sleep(0.2)
            continue

        stdscr.box()
        stdscr.addnstr(0,5, f' {sys_info}, {n} sensors ', 80) # (max_name_length={max_name_length})
        stdscr.addnstr(ny-1,5, f' Press Ctrl+C to exit ', 80)

        xmid = nx//2 # //ncol
        # __|__
        #   xmid
        #      xmid+3

        sorted_nums = get_sorted_nums(ordered_list)
        if max_nums is not None:
            max_nums = [max(x,y) for x,y in zip(sorted_nums, max_nums)]
        else:
            max_nums = sorted_nums

        # for y in range(-1, nrow1):
        #     stdscr.addnstr(nrow0+y,xmid, '|', 1)
        stdscr.vline(nrow0-1, xmid, curses.ACS_VLINE, nrow1+1)

        curses.init_pair(1, 14, -1)
        titles = ['Sensor Name','now /max˚C']
        stdscr.addnstr(nrow0-1,     2, f'{titles[0]:{max_name_length+3}}   {titles[1]}', 37, curses.color_pair(1))
        stdscr.addnstr(nrow0-1,xmid+3, f'{titles[0]:{max_name_length+3}}   {titles[1]}', 37, curses.color_pair(1))

        i = 0;
        for y in range(0, nrow1):
            if i<n:
                stdscr.addnstr(nrow0+y,     2, f'{sorted_names[i]:{max_name_length+2}}  {sorted_nums[i]:5.1f} /{max_nums[i]:5.1f}', 37)
                i += 1
        for y in range(0, nrow1):
            if i<n:
                stdscr.addnstr(nrow0+y,xmid+3, f'{sorted_names[i]:{max_name_length+2}}  {sorted_nums[i]:5.1f} /{max_nums[i]:5.1f}', 37)
                i += 1

        stdscr.refresh()
        # stdscr.getkey()
        time.sleep(0.4)

# https://stackoverflow.com/questions/21120947/catching-keyboardinterrupt-in-python-during-program-shutdown/21144662
try:
    curses.wrapper(main)
except KeyboardInterrupt:
    # print('Finish Monitoring Temperature!')
    try:
        sys.exit(0)
    except SystemExit:
        os._exit(0)
