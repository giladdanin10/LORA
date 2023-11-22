# File Name:    lora_test.py
# Description:  Automatic LoRa tests
# Auther:       Rami
# Date:         09-Jul-2023

import argparse
import json
import os
import os.path
import sys
import threading
import time
from datetime import datetime
from pickle import FALSE
from struct import pack, unpack
from threading import Event
from urllib.request import urlopen
import serial

TEST_VERSION = '0.0.2'

mission_is_running = FALSE

message_sequence = 0

bandwidth_map = [62.5, 125, 250, 500]
spreading_factor_map = [12, 11, 10, 9, 8, 7, 6]
rx_good = 0
rx_bad = 0
SNR_embedded_global = 0
results_file_name = ''
manual_attenuation = 0
user_update_request = 0
L_global = 0
N_packet_global = 0
state_global = 'init'
next_state_global = ''
current_attenuation = 0
reset_counters_sec = 0
PER_global = -1
# rcdat_http_ip = "192.168.200.77"
mission_num_global = 0
N_packet_iteration = 0
print_lora_rx_data: bool = True



reset_counters_time: float = 0.0
stop_event: Event = threading.Event()


def update_results_file(results):
    global results_file_name
    with open(results_file_name, 'a') as results_file:
        results_file.write(results)

def update_results_file(str):
    global results_file_name
    with open(results_file_name, 'a') as results_file:
        results_file.write(str)


def test_exit(exit_str):
    sys.exit(f'\n{exit_str}')


def test_abort():
    test_exit(f'Abort LoRa test')


def change_state(state_name):
    global state_global

    # global results_file_global
    state_global = state_name
    print(f'\n------------------------------')
    print(f'\tstate = {state_global}')
    print(f'------------------------------\n')

    if state_global != 'init':
        update_results_file('\n---------------------------------')
        update_results_file(f'\t{state_name}')
        update_results_file('---------------------------------\n')


def open_serial_port(_port, _baudrate=115200, _timeout=0.1):
    ser = None

    try:
        ser = serial.Serial(port=_port, baudrate=_baudrate, timeout=_timeout)
        print('Opened serial port', _port)
    except:
        test_exit(f'Failed to open serial port {_port}')

    return ser


def create_threads(rcdat_http_ip):
    try:
        threading.Thread(target=read_lora_rx_thread_func, daemon=True).start()
        threading.Thread(target=check_user_update_thread_func, daemon=True, args=(rcdat_http_ip,)).start()
    except KeyboardInterrupt:
        test_abort()
    except:
        test_exit("Failed to start thread")


def check_user_update_thread_func(rcdat_http_ip):
    global stop_event
    global L_global
    global manual_attenuation
    global print_lora_rx_data
    global state_global

    while True:
        user_input = input()
        if user_input.strip() == "":
            # time.sleep(1)
            print_lora_rx_data_pre = print_lora_rx_data
            print_lora_rx_data = False

            if not stop_event.is_set():
                stop_event.set()
                time.sleep(2)

                while True:
                    options = "enter your command:\n" \
                              "1. manual attenuation\n" \
                              "2. autonomic attenuation\n" \
                              "3 .reset_counters\n" \
                              "4. set state\n" \
                              "5. exit run\n" \
                              "6. continue run\n"
                    cmd = input(options)

                    if cmd.strip() == "1":
                        manual_attenuation = 1
                        print("set manual attenuation")
                        L_global = float(input('attenuation level='))
                        set_rcdat_attenuation(rcdat_http_ip, L_global)
                        break
                    elif cmd.strip() == "2":
                        manual_attenuation = 0
                        print("set autonomic attenuation")
                        break
                    elif cmd.strip() == "3":
                        print("reset_counters")
                        reset_receiver_counters()
                        break
                    elif cmd.strip() == "4":
                        valid = False
                        while not valid:
                            options = "enter your desired state:\n" \
                                      "1. find working point\n" \
                                      "2. measure\n"
                            cmd = input(options)
                            if cmd.strip() == "1":
                                state_global = 'find working point'
                                valid = True
                            elif cmd.strip() == "2":
                                state_global = 'measure'
                                valid = True
                            else:
                                print(f'{cmd} is not a valid state')
                                pass
                        break
                    elif cmd.strip() == "5":
                        test_exit('run stopped by user')

                    elif cmd.strip() == "6":
                        print("continue run")
                        manual_attenuation = 0
                        break
                    else:
                        print(f"{cmd} is not a legal command\n")

                stop_event.clear()
                print_lora_rx_data = print_lora_rx_data_pre


def read_lora_rx_thread_func():
    global rx_good
    global rx_bad
    global SNR_embedded_global
    global state_global
    global PER_global
    global N_packet_global
    global N_packet_iteration

    # time_init = datetime.now()
    while True:
        try:
            line = str(lora_rx_serial.readline())
            results_string = line[2:][:-5]

            if (len(results_string) != 0):
                results_json = json.loads(results_string)

                # calculate PER
                N_packet_global = float(results_json["rx_good"]) + float(results_json["rx_bad"])

                if N_packet_global != 0:
                    PER_global = float(results_json["rx_bad"] / (float(N_packet_global)))
                else:
                    PER_global = -1
                rx_good = results_json["rx_good"]
                rx_bad = results_json["rx_bad"]
                SNR_embedded_global = results_json["snr"]
                elapsed = int(time.time() - reset_counters_time)

                if print_lora_rx_data:
                    #                print(results_string)
                    #
                    # print('\n[', datetime.now().strftime("%H:%M:%S"), ']', 'results:')
                    # print('mission_num:             ', mission_num_global)
                    # print('state:                   ', state_global)
                    # print('spreading_factor:        ', results_json["spreading_factor"])
                    # print('bandwidth:               ', results_json["bandwidth"])
                    # print('rssi:                    ', results_json["rssi"])
                    # print('rx_good:                 ', results_json["rx_good"])
                    # print('rx_bad:                  ', results_json["rx_bad"])
                    # print('PER:                     ', PER_global)
                    # print('snr:                     ', SNR_embedded_global)
                    # print('attenuation:             ', current_attenuation)
                    # print('reset counters elapsed:  ', elapsed)
                    #
                    # # print('seconds:         ', results_json["seconds"])
                    # print('N_packet_iteration:  ', N_packet_iteration)
                    print(f'mission_num={mission_num_global} bw={results_json["bandwidth"]} sf={results_json["spreading_factor"]} stats={state_global} L={current_attenuation} N_packet_iteration={N_packet_iteration} elapsed={elapsed} rx_good={rx_good} rx_bad={rx_bad} PER={PER_global} SNR={SNR_embedded_global}')


        except KeyboardInterrupt:
            test_abort()
        except:
            pass


def send_to_sdr(sdr_serial, buff):
    global message_sequence

    # message to SDR format
    # MESSAGE_START 1 byte  Always 0x1B
    # SEQUENCE_NUMBER   1 byte  Incremented by one for each message sent. Wraps to zero after 0xFF is reached
    # MESSAGE_SIZE  2 bytes, MSB first  Size of the message body
    # TOKEN 1 byte  Always 0x0E
    # MESSAGE_BODY  MESSAGE_SIZE bytes
    # CHECKSUM  1 byte  Uses all characters in message including MESSAGE_START and MESSAGE_BODY. XOR of all bytes

    # print('sending to SDR')
    start = bytes([0x1B])
    token = bytes([0x0e])
    size = pack('!H', len(buff))

    # data = bytes([MESSAGE_START,SEQUENCE_NUMBER]) + size.to_bytes(2, 'big') + bytes([TOKEN]) + message
    message = start + pack('!B', message_sequence) + size + token + buff

    checksum = 0

    # calculate checksum
    for i in range(len(message)):
        checksum = checksum ^ message[i]

    # add checksum to message
    message = message + bytes([checksum])

    sdr_serial.write(message)  # write a string

    if message_sequence == 0xFF:
        message_sequence = 0
    else:
        message_sequence += 1


# Message format:
# Message Start[1] = 0x1b
# Sequence Number[1]
# Message Size[2]
# Token[1] = 0x0e
# Data[<Message Size>]
def recv_from_sdr(sdr_serial):
    status_str = {0: 'OK', 1: 'E_CMD', 2: 'E_RANGE', 3: 'E_INPROC', 4: 'E_UNKNOWN', 5: 'E_CHEKSUM',
                  6: 'E_NOT_CONFIGURED', 0x80: 'CONTINUE'}

    header_rcv = None
    data_size = None
    checksum_rcv = None

    try:
        # read header
        header_rcv = sdr_serial.read(5)
    except KeyboardInterrupt:
        test_abort()
    except:
        test_exit('failed to read header from serial')

    if len(header_rcv):
        header_list = [header_rcv[0], header_rcv[1], header_rcv[2], header_rcv[3], header_rcv[4]]
        header_arr = bytes(header_list)

        (start, sequence, data_size, token) = unpack('!bBHb', header_arr)

        if not (start == 0x1B and token == 0x0E):
            test_exit('Header error')
    else:
        test_exit('failed to read from serial')

    # read data
    data_rcv = b''
    while True:
        try:
            data_rcv += sdr_serial.read(data_size - len(data_rcv))
        except KeyboardInterrupt:
            test_abort()
        except:
            test_exit('Failed to read data from sdr serial')

        if len(data_rcv) == data_size:
            break

    (command, status) = unpack('!BB', bytes([data_rcv[0], data_rcv[1]]))

    # read checksum
    try:
        checksum_rcv = sdr_serial.read(1)
    except serial.SerialException:
        test_exit('Failed to read checksum from serial')

    s = header_rcv + data_rcv + checksum_rcv

    if len(s):
        checksum = 0
        for i in range(len(s)):
            checksum = checksum ^ s[i]
        if checksum != 0:
            print('checksum error')

        data = s[7:-1]

        return status, data
    else:
        test_exit('no reply from SDR')


def config_sdr(sdr_serial):
    # Config SDR after power up, parameters:

    print('Send config message')
    seconds = int(time.time())

    mean_motion = 14.84404506
    bstar = 0.000078084
    eqinc = 98.444499972768
    ecc = 0.0003552
    mnan = 93.49499976233
    argp = 266.585299999696
    ascn = 188.1567999995
    epoch = 20349.15254111

    rec_fmt = '!BLdddddddd59x'  # UTC Time, 8 double values, 59 reserved bytes
    message = [1, seconds, mean_motion, bstar, eqinc, ecc, mnan, argp, ascn, epoch]  # opocde is '1'

    var = pack(rec_fmt, *message)

    send_to_sdr(sdr_serial, var)
    status = recv_from_sdr(sdr_serial)
    return status


def sband(sdr_serial, mission):
    print('Send sband command:')

    print(json.dumps(mission, indent=2))

    bandwidth = 0
    spreading_factor = 0

    try:
        spreading_factor = spreading_factor_map.index(mission["spreading_factor"])
    except KeyboardInterrupt:
        test_abort()
    except:
        print('Invalid spreading factor:', mission["spreading_factor"])
        return

    try:
        bandwidth = bandwidth_map.index(mission["bandwidth"])
    except KeyboardInterrupt:
        test_abort()
    except:
        test_exit(f'Invalid bandwidth: {mission["bandwidth"]}')

    # Command(5) 1 B
    # Start Time 4 L
    # duration 1 B
    # missionType 1 B
    # tx_frequency L
    # power b
    # bandwidth  B
    # spreading_factor B
    # efc_code B
    # preamble_length B
    # payload_length B
    # delay_between_messages B

    # reserved 52 x
    rec_fmt = '!BLBBLbBBBBBBHBHBHBHBHBHBHBHBHBHB16x'  # '!BLBBLb52x'

    mission = [5,
               0,
               mission["duration"],
               3,  # LoRa
               mission["tx_frequency"],
               mission["power"],
               bandwidth,
               spreading_factor,
               mission["efc_code"],
               mission["preamble_length"],
               mission["payload_length"],
               mission["delay_between_messages"],
               mission["terminal_id"],
               mission["duration"],
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    var = pack(rec_fmt, *mission)
    try:
        send_to_sdr(sdr_serial, var)
        status = recv_from_sdr(sdr_serial)
        time.sleep(2)

    except KeyboardInterrupt:
        test_abort()
    except:
        test_exit('failed to communicate with SDR')


def stop(sdr_serial):
    print('Send stop command')
    buff = bytes([4])
    send_to_sdr(sdr_serial, buff)
    status = recv_from_sdr(sdr_serial)
    time.sleep(2)
    return status


def copy_serial_to_file(sdr_serial, file):
    while mission_is_running:
        c = sdr_serial.read(1)
        file.write(c)


def read_json_file(file_name):
    try:
        f = open(file_name)
        data = json.load(f)
        f.close()
        return data
    except KeyboardInterrupt:
        test_abort()
    except:
        test_exit(f'Failed to read file: {file_name}')


def measure_rx_signal(sdr_serial, mission, rcdat_http_ip, L_wp, search_algo_params):
    try:
        global rx_good
        global rx_bad
        global SNR_embedded_global
        global state_global
        global mission_num_global
        global L_global
        global PER_global
        global N_packet_global
        global N_packet_iteration
        global reset_counters_time

        change_state('measure')

        try:
            sband(sdr_serial, mission)
        except KeyboardInterrupt:
            test_abort()
        except:
            test_exit("Failed to start sband mission")

        try:
            L_fine = search_algo_params["L_fine"]
            T_meas = search_algo_params["T_meas"]
            # N_packet_margin = search_algo_params["N_packet_margin"]
            N_packet_first_measure = search_algo_params["N_packet_first_measure"]
            N_packet_PER_factor = search_algo_params["N_packet_PER_factor"]
            N_min_packet_iteration = search_algo_params["N_min_packet_iteration"]
            N_max_packet_iteration = search_algo_params["N_max_packet_iteration"]
            PER_min_measure = search_algo_params["PER_min_measure"]


        except KeyboardInterrupt:
            test_abort()
        except:
            test_exit(f"Failed to get search_algo_params:{search_algo_params}")

        end_measure = False
        # 1'st measurement run on L_wp with N_packet_first_measure to get a real PER measurement
        N_packet_iteration = N_packet_first_measure
        # as we add L_fine right in the 1'st iteration
        L = L_wp

        while not end_measure:
            # iteration lasts as long as the number of packets is less than assigned for this iteration and not time out
            elapsed = 0
            reset_receiver_counters()
            set_rcdat_attenuation(rcdat_http_ip, L)
            reset_counters_time = time.time()
            stop(sdr_serial)
            sband(sdr_serial, mission)
            while (N_packet_global < N_packet_iteration) and (elapsed < T_meas):
                time.sleep(1)
                elapsed = time.time() - reset_counters_time

            # update the results file
            PER = PER_global
            update_results_file(
                f'N_packet={N_packet_global} N_packet_iteration={N_packet_iteration} PER={PER:.4f} L={L} SNR_embedded={SNR_embedded_global}\n')

            # calculate the number of packets assigned for the next iteration
            if PER != 0:
                N_packet_iteration = round(
                    min(max(N_min_packet_iteration, 1 / PER * N_packet_PER_factor), N_max_packet_iteration))

            # update L for the next iteration
            # if during the measurement the user changed to manual_attenuation
            if manual_attenuation:
                if L != L_global:
                    L = L_global
            else:
                L = L - L_fine

            print(f'N_packet_global={N_packet_global}')
            # check end measure time out condition
            if PER <= PER_min_measure:
                str = f'\ntest ended due to PER<={PER_min_measure}\n'
                print(str)
                update_results_file(str)
                end_measure = True
            if N_packet_global >= N_max_packet_iteration:
                str = '\ntest ended due to N_packet_global>=N_max_packet_iteration\n'
                print(str)
                update_results_file(str)
                end_measure = True
            if elapsed >= T_meas:
                str = '\ntest ended due to elapsed >= T_meas\n'
                print(str)
                update_results_file(str)
                end_measure = True

        state_global = 'config_test'
    except KeyboardInterrupt:
        test_abort()
    except:
        test_exit("Failed to measure Rx signal")

    return True


def verify(sdr_serial, mission, search_algo_params):
    global rx_good
    T_verify = search_algo_params["T_verify"]

    #  start transmitting
    try:
        stop(sdr_serial)
        sband(sdr_serial,mission)
    except:
        test_exit("Failed to start sband mission")


# stage 0: check that we get packets at all at attenuation 0
    elapsed = 0
    stop_condition = False
    reset_receiver_counters()
    reset_counters_time = time.time()

    while (not stop_condition):
        while (manual_attenuation==1):
            L = L_global
            time.sleep(1)

        elapsed = time.time() - reset_counters_time
        stop_condition = (elapsed >= T_verify) or rx_good > 0
        # print(f'mission_num_global = {mission_num_global} find_wp_state = {find_wp_state} elapsed = {elapsed} T_wp={T_wp} N_packet_global = {N_packet_global} PER = {PER_global} L = {L}')

    if (rx_good==0):
        update_results_file(f"mission {mission_num_global} failed")
    else:
        update_results_file(f"mission {mission_num_global} success")


    state_global = 'config_test'
    return -1

def find_working_point(sdr_serial, mission, search_algo_params, rcdat_http_ip):

    global print_lora_rx_data
    global user_update_request
    global rx_bad
    global results_file_name
    global state_global
    global manual_attenuation
    global N_packet_global
    global N_packet_iteration
    global L_global

    change_state('find working point')

    #  start transmitting
    try:
        stop(sdr_serial)
        sband(sdr_serial,mission)
    except:
        test_exit("Failed to start sband mission")

    try:
        L_coarse = search_algo_params["L_coarse"]
        L_fine = search_algo_params["L_fine"]
        L_base = search_algo_params["L_base"]
        T_wp_corse = search_algo_params["T_wp_corse"]
        T_wp_fine = search_algo_params["T_wp_fine"]
        L_wp_margin = search_algo_params["L_wp_margin"]
        L_wp_margin = search_algo_params["L_wp_margin"]
        ignore_L_wp_values = search_algo_params["ignore_L_wp_values"]
        find_wp_N_packet_thresh = search_algo_params["find_wp_N_packet_thresh"]
        find_wp_only = search_algo_params["find_wp_only"]
    except:
        test_exit(f"Failed to get search_algo_params:{search_algo_params}")

    T_wp = T_wp_corse
    L_step = L_coarse
    find_wp_state = "init"
    L_wp = mission["L_wp"]
    print(type(ignore_L_wp_values))
    if ((L_wp != "") and (ignore_L_wp_values == 0)):
        update_results_file(f'Working point: L_wp={L_wp}')
        state_global = 'measure'
        return L_wp
    else:
        print("L_coarse:", L_coarse)
        print("L_base:", L_base)
        print("T_wp:", T_wp)



# stage 0: check that we get packets at all at attenuation 0
        elapsed = 0
        stop_condition = False
        T_wp = T_wp_fine
        L = 0
        set_rcdat_attenuation(rcdat_http_ip, L)
        reset_counters_time = time.time()
        # print_lora_rx_data = False
        while (not stop_condition):
            while (manual_attenuation==1):
                L = L_global
                time.sleep(1)

            elapsed = time.time() - reset_counters_time
            stop_condition = (elapsed >= T_wp) or rx_good > 0
            # print(f'mission_num_global = {mission_num_global} find_wp_state = {find_wp_state} elapsed = {elapsed} T_wp={T_wp} N_packet_global = {N_packet_global} PER = {PER_global} L = {L}')

        if (rx_good==0):
            update_results_file("could not find working point due to zero packets at L=0")
            state_global = 'config_test'
            return -1

# stage 1: find a point with at least find_wp_N_packet_thresh packets
        find_wp_state = "corse_search"
        L = L_base
        set_rcdat_attenuation(rcdat_http_ip, L)
        T_wp = T_wp_corse
        while (True):
        # if manual_attenuation wait until it is released
            while (manual_attenuation==1):
                L = L_global
                time.sleep(1)

        # if the user changed state
            if (state_global != 'find working point'):
                return L

        # update L
            L -= L_step
            set_rcdat_attenuation(rcdat_http_ip, L)

        # wait
            found_bad_frames = False
            elapsed = 0
            stop_condition = False
            reset_counters_time = time.time()
            N_packet_iteration = find_wp_N_packet_thresh
            while (not stop_condition) :
                elapsed = time.time() - reset_counters_time
                if (find_wp_state=="corse_search"):
                    stop_condition = elapsed >= T_wp
                else:
                    stop_condition = (N_packet_global>find_wp_N_packet_thresh) or (elapsed >= T_wp)
                # print(f'mission_num_global = {mission_num_global} find_wp_state = {find_wp_state} elapsed = {elapsed} T_wp={T_wp}  N_packet_global = {N_packet_global} PER = {PER_global} L = {L}')
                time.sleep((0.1))
        # check results
            if (N_packet_global != 0):
                T_wp = T_wp_fine
                L_step = L_fine
                find_wp_state = "fine_search"
                print('switch to T_wp_fine')


            if (PER_global==0):
                update_results_file("could not find working point due to zero PER")
                state_global = 'config_test'
                return -1

            elif (PER_global<0.5 and PER_global>0):
                L_wp = L
                update_results_file(f'Working point: L_wp={L_wp}')
                if (find_wp_only):
                    state_global = 'config_test'
                else:
                    state_global = 'measure'
                return L_wp

            if (L==0):
                update_results_file(f'reached L=0 exit test')
                state_global = 'config_test'
                return -1

def send_rcdat_command(rcdat_http_ip, RcdatCommand):
    PTE_Return = ''

    try:
        httpCmd = f'http://{rcdat_http_ip}/:{RcdatCommand}'

        # Send the HTTP command and try to read the result
        HTTP_Result = urlopen(httpCmd, timeout=2)
        PTE_Return = HTTP_Result.read()
    # Catch an exception if URL is incorrect (incorrect IP or disconnected)
    except KeyboardInterrupt:
        test_abort()
    except:
        test_exit("Failed to communicate with RCDAT")
        # PTE_Return = "No Response!"

    # Return the response
    return PTE_Return


def set_rcdat_attenuation(rcdat_http_ip, attenuation):
    RcdatCommand = f'SETATT={attenuation}'
    global state_global
    global current_attenuation

    current_attenuation = attenuation
    send_rcdat_command(rcdat_http_ip, RcdatCommand)
    print('\n---------------------------------------')
    print(f"{state_global}:Set attenuation to: {attenuation}")
    print('---------------------------------------\n')

    reset_receiver_counters()


def config_test(mission, results_path,session_type):
    global results_file_name
    global state_global
    global results_file_global


    mission_num = mission['mission_num']
    bandwidth = mission['bandwidth']
    spreading_factor = mission['spreading_factor']
    if (session_type=='verify'):
        results_file_name = f'{results_path}/verify_results.txt'
    elif (session_type=='evaluate'):
        results_file_name = f'{results_path}/test{mission_num}_{bandwidth}_{spreading_factor}_results.txt'

    change_state('config_test')
    # create output file
    # results_file_name = f'{results_path}/lora_results_{datetime.now().strftime("%y%m%d_%H%M%S")}.txt'
    try:
        print('Save results to', results_file_name)

        results_file_global = open(results_file_name, 'w')
        results_file_global.close()
    except FileNotFoundError:
        print('File', results_file_name, 'does not exist')
    #
    update_results_file(json.dumps(mission, indent=2))

    mission_is_running = True

    # config lora_rx
    try:
        # Set receiver bandwidth
        lora_rx_serial.write(f'bw={mission["bandwidth"]}'.encode())
        time.sleep(2)
        # Set receiver spreading factor
        lora_rx_serial.write(f'sf={mission["spreading_factor"]}'.encode())
        time.sleep(2)
        # Reset RH counters
        reset_receiver_counters()
        time.sleep(2)
    except KeyboardInterrupt:
        test_abort()
    except:
        test_exit("Failed to configure lora_rx")

    start_time = time.time()
    if (session_type == 'evaluate'):
        state_global = 'find working point'

    elif (session_type == 'verify'):
        state_global = 'verify'

def reset_receiver_counters():
    try:
        global reset_counters_time

        print('Reset Receiver Counters')
        lora_rx_serial.write('reset'.encode())
        reset_counters_time = time.time()
        time.sleep(2)
    except KeyboardInterrupt:
        test_abort()
    except:
        test_exit("Failed to reset receiver counters")


def main(argv):
    # global sdr_serial
    global lora_rx_serial
    global state_global
    # global results_file_global
    global results_file_name
    # global rcdat_http_ip
    global mission_num_global

    # lora_test_conf_file = 'lora_test_conf.json'
    lora_test_conf_file = 'lora_test_conf.json'
    change_state('init')
    print('Running', os.path.basename(__file__), ', Version', TEST_VERSION)

    # Command line parser
    parser = argparse.ArgumentParser(description='Lora Test')
    parser.add_argument('-f', metavar='<config file>', help='configuration JSON file (i.e., lora_mission.json',
                        required=False)
    args = parser.parse_args()

    args_dict = vars(args)

    for key, arg in args_dict.items():
        if key == 'f':
            if arg is not None:
                lora_test_conf_file = arg
                continue

    print("Configuration file is", lora_test_conf_file)

    configuration = read_json_file(lora_test_conf_file)

    try:
        ports = configuration["ports"]
        missions = configuration["missions"]
        missions_to_run = configuration["missions_to_run"]
        tx_type = configuration["tx_type"]
        tx_frequency_session = configuration["tx_frequency_session"]
        session_type = configuration["session_type"]


        if missions_to_run == "":
            missions_to_run = list(range(0, len(missions)))
        else:
            print(type(missions_to_run))

        search_algo_params = configuration["search_algo_params"]
        rcdat_http_ip = configuration["rcdat_http_ip"]

        sdr_port = ports["sdr_port"]
        lora_rx_port = ports["lora_rx_port"]
        lora_rx_port_baud_rate = ports["lora_rx_port_baud_rate"]

        results_path = configuration["results_path"]
    except KeyboardInterrupt:
        test_abort()
    except:
        test_exit("Configuration file is invalid")

    # Open serial ports
    sdr_serial = open_serial_port(sdr_port, 115200, 0.1)
    lora_rx_serial = open_serial_port(lora_rx_port, lora_rx_port_baud_rate, 0.1)

    create_threads(rcdat_http_ip)

    try:
        os.mkdir(results_path)
    except OSError as error:
        pass

    status = config_sdr(sdr_serial)
    if not status:
        test_exit('failed to config SDR')
    time.sleep(0.2)
    stop(sdr_serial)
    time.sleep(0.2)

    # Get RCDAT details
    print('RCDAT model:', send_rcdat_command(rcdat_http_ip, "MN?"))
    print('RCDAT serial number:', send_rcdat_command(rcdat_http_ip, "SN?"))

    start_test_sec = time.time()

    state_global = 'config_test'

    L_wp = 0

    for mission_num_global in missions_to_run:
        # while (mission_num_global < len(missions)):
        mission = missions[mission_num_global]

# if the tx_frequency for this mission is not configured, take tx_frequency_session
        if (len(mission["tx_frequency"])==0):
            mission["tx_frequency"] = tx_frequency_session

        if state_global == 'config_test':
            config_test(mission, results_path,session_type)

        if (state_global == 'verify'):
            status = verify(sdr_serial, mission, search_algo_params)

        if state_global == 'find working point':
            L_wp = find_working_point(sdr_serial, mission, search_algo_params, rcdat_http_ip)

        if state_global == 'measure':
            measure_rx_signal(sdr_serial, mission, rcdat_http_ip, L_wp, search_algo_params)

    print('Tests took', int(time.time() - start_test_sec), 'sec')
    print('------------------')
    print('test ended')
    print('------------------')
    # close port
    sdr_serial.close()
    lora_rx_serial.close()


if __name__ == '__main__':
    try:
        main(sys.argv)
    except KeyboardInterrupt:
        test_abort()
