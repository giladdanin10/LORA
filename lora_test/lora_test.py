# File Name:    lora_test.py
# Description:  Automatic LoRa tests
# Auther:       Rami
# Date:         09-Jul-2023

from struct import pack, unpack, unpack_from

import csv
from datetime import datetime
import serial
import time
import hashlib
from timeit import default_timer as timer

import sys
import csv
from datetime import datetime
import os
import os.path

import argparse
import json
from pickle import FALSE

from urllib.request import urlopen

import threading

TEST_VERSION='0.01'

mission_is_running = FALSE

message_sequence = 0

bandwidth_map = [62.5, 125, 250, 500]
spreading_factor_map = [12, 11, 10, 9, 8, 7, 6]
rx_good = 0
rx_bad = 0
snr = 0;

def read_lora_rx_thread():
    #time_init = datetime.now()
    while True:
        try:
            line = str(lora_rx_serial.readline())
            results_string = line[2:][:-5]
            
            if(len(results_string) != 0):
#                print(results_string)
                
                results_json = json.loads(results_string)
                print('[', datetime.now().strftime("%H:%M:%S"), ']', 'results:')
                print('spreading_factor:', results_json["spreading_factor"])
                print('bandwidth:       ', results_json["bandwidth"])
                print('rssi:            ', results_json["rssi"])
                print('rx_good:         ', results_json["rx_good"])
                print('rx_bad:          ', results_json["rx_bad"])
                print('snr:             ', results_json["snr"])
                print('seconds:         ', results_json["seconds"])

                rx_good = results_json["rx_good"]
                rx_bad = results_json["rx_bad"]
                snr = results_json["snr"]
        except:
            pass

def SendToSdr(buff):
    global message_sequence
    
#message to SDR format
# MESSAGE_START 1 byte  Always 0x1B
# SEQUENCE_NUMBER   1 byte  Incremented by one for each message sent. Wraps to zero after 0xFF is reached
# MESSAGE_SIZE  2 bytes, MSB first  Size of the message body
# TOKEN 1 byte  Always 0x0E
# MESSAGE_BODY  MESSAGE_SIZE bytes  
# CHECKSUM  1 byte  Uses all characters in message including MESSAGE_START and MESSAGE_BODY. XOR of all bytes

    #print('sending to SDR')
    start = bytes([0x1B])
    token = bytes([0x0e])
    size=pack('!H',len(buff)) 
    
    #data = bytes([MESSAGE_START,SEQUENCE_NUMBER]) + size.to_bytes(2, 'big') + bytes([TOKEN]) + message 
    message = start + pack('!B', message_sequence) + size + token + buff 

    checksum = 0

    #calculate checksum
    for i in range(len(message)):
        checksum = checksum ^ message[i]
        
    #add checksum to message
    message = message + bytes([checksum]) 

    sdr_serial.write(message)     # write a string
    
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
def RecvFromSdr():
    status_str = {0:'OK', 1:'E_CMD', 2:'E_RANGE', 3:'E_INPROC', 4:'E_UNKNOWN', 5:'E_CHEKSUM', 6:'E_NOT_CONFIGURED', 0x80:'CONTINUE'}

    try:
        # read header
        header_rcv = sdr_serial.read(5)
    except:
        print('failed to read header from serial')
        return
        
    if len(header_rcv):
        header_list = [header_rcv[0], header_rcv[1], header_rcv[2], header_rcv[3], header_rcv[4]]
        header_arr = bytes(header_list)        
        
        (start, sequence, data_size, token) = unpack('!bBHb', header_arr)
        
        if not (start==0x1B and token==0x0E) :
            print('Header error')

    # read data
    data_rcv = b''
    while True:
        try:
            data_rcv += sdr_serial.read(data_size - len(data_rcv))
        except:
            print('Failed to read data from sdr serial')
            return

        if len(data_rcv) == data_size:
            break
            
    (command, status) = unpack('!BB', bytes([data_rcv[0], data_rcv[1]]))

    #read checksum
    try:
        checksum_rcv = sdr_serial.read(1)
    except:
        print('Failed to read checksum from serial')
        return
    
    s = header_rcv + data_rcv + checksum_rcv

    if len(s):
        checksum = 0
        for i in range(len(s)):
            checksum = checksum ^ s[i]
        if checksum!=0 :
            print('checksum error')
        
        data = s[7:-1]
        
        return status, data
        
    else:
        print('no reply from SDR\n')
        return -1
     
def config():
    # Config SDR after power up, parameters:

    print('Send config message')
    seconds = int(time.time())
    
    mean_motion = 14.84404506
    bstar = 0.000078084
    eqinc  = 98.444499972768
    ecc = 0.0003552
    mnan  = 93.49499976233
    argp  = 266.585299999696
    ascn  = 188.1567999995
    epoch = 20349.15254111
    
    rec_fmt = '!BLdddddddd59x'  # UTC Time, 8 double values, 59 resereved bytes
    message=[1,seconds,mean_motion,bstar,eqinc ,ecc,mnan ,argp ,ascn ,epoch]  #opocde is '1'

    var = pack(rec_fmt,*message)
    
    SendToSdr(var)
    RecvFromSdr()

def sband(mission):
    print('Send sband command:')
    
    print(json.dumps(mission, indent=2))
    
    try:
        spreading_factor = spreading_factor_map.index(mission["spreading_factor"])
    except:
        print('Invalid spreading factor:', mission["spreading_factor"])
        return
    
    try:
        bandwidth = bandwidth_map.index(mission["bandwidth"])
    except:
        print('Invalid bandwidth:', mission["bandwidth"])
        return

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
    rec_fmt = '!BLBBLbBBBBBBHBHBHBHBHBHBHBHBHBHB16x' #'!BLBBLb52x'
    
    mission=[5, 
             0, 
             mission["duration"], 
             3, # LoRa
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
             0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    
    var = pack(rec_fmt,*mission)
    try:
        SendToSdr(var)
        RecvFromSdr()
    except:
        print('failed to communicate with SDR')
        
def stop():
    print('Send stop command')
    buff=bytes([4])
    SendToSdr(buff)
    RecvFromSdr()

def CopySerialToFile(sdr_serial, file):
    while mission_is_running:
        c = sdr_serial.read(1)
        file.write(c)
    
def ReadJsonFile(file_name):
    f = open(file_name)
    data = json.load(f)
    f.close()
    return data

def MeasureRxSignal(rcdat_http_ip, L_wpm, duration, search_algo_params):
    print('Measure Rx signal')

    start_sec = time.time()
    L = L_wp
    
    SetRcdatAttenuation(rcdat_http_ip, L)

    try:
        L_fine = search_algo_params["L_fine"]
        T_meas = search_algo_params["T_meas"]
    except:
        print("Failed to get search_algo_params:", search_algo_params)
        sys.exit(-1)

    while(True):
        ResetReceiverCounters()
        L += L_fine
        SetRcdatAttenuation(rcdat_http_ip, L)
        time.sleep(T_meas)
        PER = rx_bad / (rx_good + rx_bad)
        SNR = snr
        
        if(rx_good != 0):
            break
        
        if(time.time() - start_sec >= duration):
            break
    
def FindWorkingPoint(duration, search_algo_params):
    print('Find working point')
    
    try:
        start_sec = time.time()
        
        L_coarse = search_algo_params["L_coarse"]
        L_base = search_algo_params["L_base"] 
        T_wp = search_algo_params["T_wp"]
        
        print("L_coarse:", L_coarse)
        print("L_base:", L_base)
        print("T_wp:", T_wp)
    except:
        print("Failed to get search_algo_params:", search_algo_params)
        sys.exit(-1)

    L = L_base
    ResetReceiverCounters()
    time.sleep(2)
    
    while(True):
        L += L_coarse
        time.sleep(T_wp)
        if(rx_bad > 1):
            break
    
    print('Working point: L_wp:', L)    
    return L
        
def SendRcdatCommand(rcdat_http_ip, RcdatCommand):
    httpCmd = f'http://{rcdat_http_ip}/:{RcdatCommand}'

    # Send the HTTP command and try to read the result
    try:
        HTTP_Result = urlopen(httpCmd, timeout=2)
        PTE_Return = HTTP_Result.read()
    # Catch an exception if URL is incorrect (incorrect IP or disconnected)
    except:
        print ("Error, no response from device; check IP address and connections.")
        PTE_Return = "No Response!"
        sys.exit()      # Exit the script

    # Return the response
    return PTE_Return

def SetRcdatAttenuation(rcdat_http_ip, attenuation):
    RcdatCommand = f'SETATT={attenuation}'
    
    try:
        SendRcdatCommand(rcdat_http_ip, RcdatCommand)
        print ("Set attenuation to: ", str(SendRcdatCommand("ATT?")))
    except:
        print ("Failed to set attenuation")
        sys.exit()
         
def ResetReceiverCounters():
    lora_rx_serial.write('reset'.encode())
       
def main(argv):
    global sdr_serial
    global lora_rx_serial
    
    lora_test_conf_file = 'lora_test_conf.json'
    
    print('Running', os.path.basename(__file__), ', Version', TEST_VERSION)
    
    # Command line parser
    parser = argparse.ArgumentParser(description='Lora Test')
    parser.add_argument('-f', metavar='<config file>', help='configuration JSON file (i.e., lora_mission.json', required=False)
    args = parser.parse_args()
    
    args_dict = vars(args)
    
    for key, arg in args_dict.items():
        if key == 'f':
            if arg != None:
                lora_test_conf_file = arg
                continue
    
    print("Configuration file is", lora_test_conf_file)
    
    results_path='./results'

    try:
        configuration = ReadJsonFile(lora_test_conf_file)
    except:
        print("Failed to read file:", lora_test_conf_file)
        sys.exit(-1)
    
    try:
        ports = configuration["ports"]
        missions = configuration["missions"]
        search_algo_params = configuration["search_algo_params"]
        rcdat_http_ip = configuration["rcdat_http_ip"]
        
        sdr_port = ports["sdr_port"]
        lora_rx_port = ports["lora_rx_port"]
        lora_rx_port_baud_rate = ports["lora_rx_port_baud_rate"]
    except:
        print("Configuration file is invalid")
        sys.exit(0)
    
    try:    
        results_path = configuration["results_path"]
    except:
        pass
        
    #Open serial ports
    try:
        sdr_serial = serial.Serial(sdr_port, 115200, timeout=0.1)  # open serial port, 2 seconds timeout 
        print('Opened serial port', sdr_port)
    except:
        print("Failed to open sdr serial port", sdr_port)
        sys.exit(-1)

    try:
        lora_rx_serial = serial.Serial(lora_rx_port, lora_rx_port_baud_rate, timeout=0.1)  # open serial port, 2 seconds timeout 
        print('Opened serial port', lora_rx_port)
        time.sleep(3)
    except:
        print("Failed to open lora_rx serial port", lora_rx_port)
        sys.exit(-1)

    try:
        threading.Thread(target=read_lora_rx_thread, daemon=True).start()
    except:
        print("Failed to start thread")
        sys.exit(-1)

    try:
        os.mkdir(results_path)
    except OSError as error:
        pass
    
    config()
    time.sleep(0.2)
    stop()
    time.sleep(0.2)
    
    #Get RCDAT details
    print('RCDAT model:', SendRcdatCommand(rcdat_http_ip, "MN?"))
    print('RCDAT serial number:', SendRcdatCommand(rcdat_http_ip, "SN?"))
    
    start_test_sec = time.time()
    
    for mission in missions:
        print('Running mission', mission['mission_num'])
        
        #create output file
        results_file_name = f'{results_path}/lora_results_{datetime.now().strftime("%y%m%d_%H%M%S")}.txt'
        
        try:
            print('Save results to', results_file_name)
            
            with open(results_file_name, 'w') as results_file:
                results_file.write(json.dumps(mission, indent=2))
                
        except FileNotFoundError:
            print('File', results_file_name, 'does not exist')
            
        mission_is_running = True

        #config lora_rx
        try:
            #Set receiver bandwidth
            lora_rx_serial.write(f'bw={mission["bandwidth"]}'.encode())
            time.sleep(2)
            #Set receiver spreading factor
            lora_rx_serial.write(f'sf={mission["spreading_factor"]}'.encode())
            time.sleep(2)
            #Reset RH counters
            ResetReceiverCounters()
#            time.sleep(2)
        except:
            print("Failed to configure lora_rx")
            sys.exit(-1)
        
        #start S-BAND mssiom
        try:
            sband(mission)
            mission_duration_sec = mission['duration'] * 10 + 1
#            print("Wait", mission_duration_sec, ' seconds for mission to end')
#            time.sleep(mission_duration_sec)
        except:
            print("Failed to start sband mission")
            sys.exit(-1)
        
        start_time = time.time()
        try:
            L_wp = FindWorkingPoint(mission_duration_sec, search_algo_params)
        except:
            print("Failed to find working point")
            sys.exit(-1)
        
        passed_time = time.time()
        mission_time_left = mission_duration_sec - passed_time
        
        try:
            MeasureRxSignal(rcdat_http_ip, L_wp, mission_time_left, search_algo_params)
        except:
            print("Failed to measure Rx signal")
            sys.exit(-1)

            
    print('Tests took', int(time.time() - start_test_sec), 'sec')
    # close port
    sdr_serial.close()
    lora_rx_serial.close()
    sys.exit()

if __name__ == '__main__':
    main(sys.argv)
    