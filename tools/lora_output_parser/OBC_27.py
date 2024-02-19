# added shutdown command 30-9-2020, Izhar
# added generic command 01-10-2020, Rami
# support mission delay time instead of EPOCH time
# add reserved bytes to: Config, Ka, NN, S-Band, Get Status
# add Output Backoff parameter to Ka Mission


from struct import pack, unpack, unpack_from
import csv
from datetime import datetime
import serial
import time
import hashlib
from timeit import default_timer as timer

import sys
from prompt_toolkit import prompt
from prompt_toolkit.history import FileHistory
from prompt_toolkit.auto_suggest import AutoSuggestFromHistory
from prompt_toolkit.completion import WordCompleter
import csv
from datetime import datetime
import os.path

import argparse

number_of_bytes_to_print = 100

#PORT='/dev/ttyS0'        # Amit
#PORT='/dev/ttyUSB0'       # Rami's PC
PORT='/dev/ttyUSB3'       # Rami's ZCU102

OBC_VERSION='0.25'

def ReadCsvFile(file_name):
    with open(file_name, 'r') as f:
        reader = csv.reader(f)
        data_list = list(reader)
        #print(mission_list)
        return data_list

def ConvertKaMission(mission, sessions, reserved_bytes):
#Send mission start command
# Command(2) 1 B
# Start Time 4 L
# Mission Type 1 B
# Tx frequency 4 L
# Rx frequency 4 L
# Tx Symbol Rate 4 L 
# Rx Symbol Rate 4 L
# Tx Mode 1 B
# Tx MODCOD 1 B
# Rx Mode 1 B
# Rx MODCOD 1 B 
# Session #1, Terminal ID 2 H
# Session #1, Duration 1 B

# Session #10, Terminal ID  2 
# Session #10, Duration  1
    rec_fmt = '!LBLLLLBBBB'
    session_fmt='!HB'
    reserved_fmt = '!B'
    
    mission[0]= int(mission[0])
    mission[1]= int(mission[1])
    mission[2]= int(mission[2])
    mission[3]= int(mission[3])
    mission[4]= int(mission[4])
    mission[5]= int(mission[5])
    if mission[6]=='ACM':
        mission[6]=0
    elif mission[6]=='CCM':
        mission[6]=1
    else:
        print('error in file')
        return
    mission[7]= int(mission[7])
    if mission[8]=='ACM':
        mission[8]=0
    elif mission[8]=='CCM':
        mission[8]=1
    else:
        print('error in file')
        return
    mission[9]= int(mission[9])
    #print(mission)
    #print(sessions)
    var = pack(rec_fmt,*mission)
    
    for session in sessions:
        if session[0]!=0:
            #print(session)
            session[0]=int(session[0])  
            session[1]=int(session[1])
        var = var + pack(session_fmt,*session)
        
    #Handle reserved bytes
    reserved_bytes[0]=int(reserved_bytes[0])
    var = var + pack(reserved_fmt,*reserved_bytes)
     
    var=bytes([2]) + var  #add 2 which is the command number
    # for i in range(len(var)):
        # print(hex(var[i]),',', end='')
    # print()
    reserved = '\0' * 24
    var += reserved.encode()
    
    return var

message_sequence = 0
def SendToSdr(buff, auto_get_status=False):
    global message_sequence
    
#message to OBC format
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

    if not auto_get_status:
        print ('Send', len(message), 'bytes: ')
        for i in range(len(message)):
            print (hex(message[i]) + ' ', end='')
            if i > number_of_bytes_to_print:
                print('...', end='')
                break
        print()
        print()
        
#    for i in range(len(message)):
#        if i<30:
#            if not auto_get_status:
#                print (hex(message[i]) + ' ', end='')
#        else:
#            if not auto_get_status:
#                print('...')
#            break

    #ser = serial.Serial('/dev/ttyS0', 115200)  # open serial port
    #ser = serial.Serial('com5', 115200)  # open serial port
    ser.write(message)     # write a string
    
    if message_sequence == 0xFF:
        message_sequence = 0
    else:
        message_sequence += 1
    #ser.close()             # close port

# Message format:
# Message Start[1] = 0x1b
# Sequence Number[1]
# Message Size[2]
# Token[1] = 0x0e
# Data[<Message Size>]
def RecvFromSdr(auto_get_status=False):
    status_str = {0:'OK', 1:'E_CMD', 2:'E_RANGE', 3:'E_INPROC', 4:'E_UNKNOWN', 5:'E_CHEKSUM', 6:'E_NOT_CONFIGURED', 0x80:'CONTINUE'}
    print_message_details = False

    try:
        # read header
        header_rcv = ser.read(5)
    except:
        print('failed to read header from serial')
        return
        
    if len(header_rcv):
        header_list = [header_rcv[0], header_rcv[1], header_rcv[2], header_rcv[3], header_rcv[4]]
        header_arr = bytes(header_list)        
        
        (start, sequence, data_size, token) = unpack('!bBHb', header_arr)
        
        if print_message_details:
            if not auto_get_status:
                print('Received message:')
                print('start:    ', hex(start))
                print('sequence: ', sequence)
                print('size:     ', data_size)
                print('token:    ', hex(token))
            
        if not (start==0x1B and token==0x0E) :
            if not auto_get_status:
                print('Header error')

    # read data
    data_rcv = b''
    while True:
        try:
            data_rcv += ser.read(data_size - len(data_rcv))
        except:
            if not auto_get_status:
                print('failed to read data from serial')
            return

        if len(data_rcv) == data_size:
            break
            
    (command, status) = unpack('!BB', bytes([data_rcv[0], data_rcv[1]]))
    if not auto_get_status:
        if print_message_details:
            print('command:  ', hex(command))

    #read checksum
    try:
        checksum_rcv = ser.read(1)
    except:
        print('failed to read checksum from serial')
        return
    
    if print_message_details:
        if not auto_get_status:
            print('checksum: ', hex(checksum_rcv[0]))
    
    s = header_rcv + data_rcv + checksum_rcv

    if not auto_get_status:
        print('received', len(s), 'bytes: ')
        for i in range(len(s)):
            print (hex(s[i]) + ' ', end='')
            if i > number_of_bytes_to_print:
                print('...', end='')
                break
        print()
        print()

    if not auto_get_status:
        if status in status_str:
            print('status:   ', status_str[status])
        else:
            print('unknown error:   ', status)

    if len(s):
        checksum = 0
        for i in range(len(s)):
            checksum = checksum ^ s[i]
        if checksum!=0 :
            if not auto_get_status:
                print('checksum error')
        
        data = s[7:-1]
        if not auto_get_status:
            print('data: ', end='')
            if len(data) == 0:
                print('none')
            else:
                for i in range(len(data)):
                    print (hex(data[i]) + ' ', end='')
                    if i > number_of_bytes_to_print:
                        print('...', end='')
                        break
                print()
            print()
            
        #if not auto_get_status:
        #    print()
            
        return status, data
        
    else:
        if not auto_get_status:
            print('no reply from SDR')
            print()
        return -1

def nop():
    print('sending nop command')
    buff=bytes([0])
    SendToSdr(buff)
    RecvFromSdr()
    
def shutdowncmd():
    print('sending shutdown command')
    buff=bytes([9])
    SendToSdr(buff)
    RecvFromSdr()


def ka():
    print('Send ka mission')
    
    type=input('Enter mission type (0-term, 1-gw, 2-gw_cw, 3-term_dvb_s2, 4-term_cw): ')
    
    if type == '0':
        mission_file = 'mission_term.txt'
    elif type == '1':
        mission_file = 'mission_gw.txt'
    elif type == '2':
        mission_file = 'mission_gw_cw.txt'
    elif type == '3':
        mission_file = 'mission_term_dvb_s2.txt'
    elif type == '4':
        mission_file = 'mission_term_cw.txt'
    else:
        print('Invalid Ka mission type')
        return

    try:
        missions=ReadCsvFile(mission_file)
    except:
        print('Failed to open file', mission_file)
        return

    sessions=[]
    for i in range(0,10):
        sessions.append([0,0])
         
    for mission in missions:
        print()

        for i in range(0,10):
            try:
                sessions[i]=[mission[10+i*2],mission[11+i*2]]
                #print(' terminal:',mission[10+i*2],end='')
            except:
                pass
            
        reserved_bytes = [mission[30]]
        
        print()

        buff = ConvertKaMission(mission[0:10], sessions, reserved_bytes)
        SendToSdr(buff)
        RecvFromSdr()
        #keep sending all missions or exit ? for now quit
        print('sending only first mission - done !')
        break
     
def config():
    # Config SDR after power up, parameters:

    print('Send config message')
    seconds = int(time.time())
    #mean_motion = 15.72125391  #14.84404506
    #bstar = -1.1606 #0.000078084
    #eqinc  = 0.901315951 #1.718180655
    #ecc = 0.0006703 #0.0003552
    #mnan  = 5.67282272379 #1.63179558
    #argp  = 2.278282992 #4.6527912224
    #ascn  = 4.3190388909 #3.28395567
    #epoch = 08264.51782528 #20349.15254111
    
    # Example 1
    # TLE:
    # 1 40074U 14037F   20349.15254111  .00000596  00000-0  78084-4 0  9999
    # 2 40074  98.4445 188.1568 0003552 266.5853  93.4950 14.84404506348414
    
    mean_motion = 14.84404506
    bstar = 0.000078084
    eqinc  = 98.444499972768
    ecc = 0.0003552
    mnan  = 93.49499976233
    argp  = 266.585299999696
    ascn  = 188.1567999995
    epoch = 20349.15254111
    
    #Example 2
    #mean_motion = 14.99209795
    #bstar =  0.00047501
    #eqinc  =  97.8081
    #ecc = 0.0018467
    #mnan  = 35.3696
    #argp  = 324.6300
    #ascn  = 3.9071
    #epoch = 22034.13865007

    rec_fmt = '!BLdddddddd59x'  # UTC Time, 8 double values, 59 resereved bytes
    message=[1,seconds,mean_motion,bstar,eqinc ,ecc,mnan ,argp ,ascn ,epoch]  #opocde is '1'

    var = pack(rec_fmt,*message)
    
    SendToSdr(var)
    RecvFromSdr()


def nogah():
        # Start a NOGAH-NANO mission, parameters:
        # Mission start time (4 bytes)
        # Duration (1 bytes)
        # File Number (1 bytes)
        # Spare (2 bytes)
        # 24 bytes generic mission parameters

    print('Send nano nogha mission command')

    DurationStr = input("Enter duration (10 x sec): ")
    try:
        duration=int(DurationStr)
    except:
        print('bad duration input')
        return  

    FileNumStr = input("Enter file number: ")
    try:
        filenum=int(FileNumStr)
    except:
        print('bad file number input')
        return  


    # print("Seconds since epoch =", seconds)
    # print("duraiton", duration)
    # print('file number',filenum)
    
    # Command(3) 1 B
    # Start Time 4 L
    # duration 1 B
    # file number 1 B
    # reserved 42  x
    rec_fmt = '!BLBB42x'
    mission=[3,0, duration, filenum]
    
    var = pack(rec_fmt,*mission)
    
    SendToSdr(var)
    RecvFromSdr()

def ConvertLoRaMission(lora_params):

# bandwidthCode         1 B
# spreadingFactor       1 B
# ecfCode               1 B
# preambleLength        1 B
# payloadLength         1 B
# delayBetweenMessages  1 B
# Session #1, Terminal ID    2 H
# Session #1, Duration       1 B
# ...
# Session #10, Terminal ID   2 H 
# Session #10, Duration      1 B
# Reserved         16 x

    duration=0
    rec_fmt = '!BBBBBBHBHBHBHBHBHBHBHBHBHB16x'
    for i in range(0,6):
        lora_params[i]= int(lora_params[i])
#    lora_params[0]= int(lora_params[0]) # bandwidthCod
#    lora_params[1]= int(lora_params[1]) # spreadingFactor
#    lora_params[2]= int(lora_params[2]) # ecfCode
#    lora_params[3]= int(lora_params[3]) # preambleLength
#    lora_params[4]= int(lora_params[4]) # payloadLength
#    lora_params[5]= int(lora_params[5]) # delayBetweenMessages
    
    # sessions:
    for i in range(0,10):
        lora_params[6+i*2]=int(lora_params[6+i*2])     # terminal id
        lora_params[6+i*2+1]=int(lora_params[6+i*2+1]) # session duration
        duration+=lora_params[6+i*2+1]
        print('term id:          ', lora_params[6+i*2])
        print('session duration: ', lora_params[6+i*2+1]*10, ' sec')
        
    print('mission duration: ', duration*10, ' sec')
        
    var = pack(rec_fmt,*lora_params)
    
    # for i in range(len(var)):
        # print(hex(var[i]),',', end='')
    # print()
    
    return duration,var

def sband():
        # Start a S-band mission, parameters:
        # Mission start time (4 bytes)
        # Duration (1 bytes)
        # power (1 bytes signed)
	# mission type (1 bytes unsigned)
        # Spare (1 byte)
        # Tx freq (4 bytes)
        # 24 bytes generic mission parameters

    print('Send S-band mission command')

    missionTypeStr = input("Enter mission type (0 - CW, 1 - DVB_S2, 2 - HS, 3 - LoRa, 4 - Lora Recorded): ")
    try:
        missionType=int(missionTypeStr)
    except:
        print('bad type input')
        return

    FreqStr = input("Enter frequecy (KHz): ")
    try:
        freq=int(FreqStr)
    except:
        print('bad frequecy input')
        return

    PowerStr = input("Enter power backoff (dB): ")
    try:
        power=int(PowerStr)
    except:
        print('bad power input')
        return


    if missionType == 3 or missionType == 4:    # LoRa mission 
        lora_params=ReadCsvFile('sband_lora_mission.txt')
        print('lora_params: ', lora_params[0]) #????
        duration,fmt_lora_params = ConvertLoRaMission(lora_params[0])
    elif missionType == 1:                      # DVB-S2
        dvbs2_params=ReadCsvFile('sband_dvbs2_mission.txt')
        print('dvbs2_params: ', dvbs2_params[0]) #????
        duration,fmt_dvbs2_params = ConvertLoRaMission(dvbs2_params[0])
    else:
        DurationStr = input("Enter duration (10 x sec): ")
        try:
            duration=int(DurationStr)
        except:
            print('bad duration input')
            return

    # Command(5) 1 B
    # Start Time 4 L
    # duration 1 B
    # missionType 1 B
    # tx freq 4 L
    # power 1 b
    # reserved 52 x
    rec_fmt = '!BLBBLb' #'!BLBBLb52x'
    
    mission=[5, 0, duration, missionType, freq, power]
    
    var = pack(rec_fmt,*mission)
    
    if missionType == 3 or missionType == 4:
        var += fmt_lora_params
    elif missionType == 1:
        var += fmt_dvbs2_params
    else:
        var += pack('!52x')
        
    SendToSdr(var)
    RecvFromSdr()
    
def generic():
        # Send generic command, parameters:
        # buffer (1024 bytes)

    print('Send generic command')

    BLOCKSIZE = 1024

    buffer=bytearray(BLOCKSIZE)
    buffer[0]=0x06
    SendToSdr(buffer)
    try:
        status, reply = RecvFromSdr()
    except:
        print('failed to get SDR reply')
        return

def stop():
    print('Send stop command')
    buff=bytes([4])
    SendToSdr(buff)
    RecvFromSdr()

def get_status(auto_get_status=False):
    if not auto_get_status:
        print('Send get status command')
    buff=bytes([0x30])
    try:
        SendToSdr(buff, auto_get_status)
        status, reply = RecvFromSdr(auto_get_status)
    except:
        if not auto_get_status:
            print('Get Status failed')
        #raise
        return

#x - pad byte
#b - signed char
#B - unsigned char
#h - short
#H - unsigned short
#L - unsigned long

    rec_fmt = '!LHBBBLBLhhhhhhhhhhxLLBBBBBBBBBHHBH'
    result_keys = ['UTC Time', 
                   'SW Version',
                   'HW Version Major',
                   'HW Version Minor',
                   'General Status',
                   'BIT Result',
                   'Operation Mode',
                   'Uptime',
                   '3.3v Indication',
                   '5v Indication',
                   '6.5v Indication',
                   '-5v Indication',
                   'SDR 3.3v Indication',
                   'Transceiver Temperature',
                   'Q8 Temperature',
                   'Q8 DB Temperature', 
                   'LNA Temperature',
                   'PA Temperature',
                   'Tx Frequency',
                   'Rx Frequency',
                   'PLL Locks',
                   'Output Backoff',
                   'Rx Signal Level',
                   'Rx SNR',
                   'Far Side SNR',
                   'Tx MODCOD ',
                   'Rx MODCOD',
                   'PWM',
                   'RX Gain',
                   'PA Detector',
                   'Uplink Bit Rate (Mbps)',
                   'Flash Status',
                   'LOG File Number']
    status_log_name = 'Status_log.csv'
    print("reply:", reply) ##########################
    
    result=unpack(rec_fmt, reply)
    result_dict = dict(zip(result_keys, result))

    if auto_get_status:
        try:
            if os.path.isfile(status_log_name):
                #print ("Append status to file: ", status_log_name)
                open_prop = 'a'
            else:
                print ("Write status to file: ", status_log_name)
                open_prop = 'w'
                
            with open(status_log_name, open_prop, newline='') as log:
                writer = csv.writer(log)
                if open_prop == 'w':
                    writer.writerow(['Time'] + result_keys)
                writer.writerow([datetime.now()] + list(result_dict.values()))
        except:
            print("Failed to write to file: ", status_log_name)
            return
    else:
        try:

            for key, res in result_dict.items():
                if key == 'UTC Time':
                    dt_object = datetime.utcfromtimestamp(res)
                    print("{:<30} {:<10}".format(key, str(dt_object)))
                elif key == 'SW Version':
                    print("{:<30} {:<10}".format('SW Version', str(result_dict['SW Version'] >> 13) + '.' + str((result_dict['SW Version'] >> 5) & 0xFF) + '.' + str(result_dict['SW Version'] & 0x1F)))
                elif key == 'HW Version Major':
                    print("{:<30} {:<10}".format('HW Version', str(result_dict['HW Version Major']) + '.' + str(result_dict['HW Version Minor'])))
                elif key == 'HW Version Minor':
                    continue
                elif key == 'BIT Result':
                    print("{:<30} {:<10}".format(key, ''.join([ '0x', hex(res).upper()[2:].zfill(2)])))
                elif key == 'General Status':
                    print("{:<30} {:<10}".format(key, ''.join([ '0x', hex(res).upper()[2:].zfill(2)])))
                    print("{:<30} {:<10}".format("   Rx Locked",        (res & 0x1) >> 0))
                    print("{:<30} {:<10}".format("   testPatternBerOk", (res & 0x2) >> 1))
                    print("{:<30} {:<10}".format("   dataRxOk",         (res & 0x4) >> 2))
                    print("{:<30} {:<10}".format("   udtPer",           (res & 0x8) >> 3))
                elif key == 'PLL Locks':
                    print("{:<30} {:<10}".format(key, ''.join([ '0x', hex(res).upper()[2:].zfill(2)])))
                elif key == 'Flash Status':
                    print("{:<30} {:<10}".format(key, ''.join([ '0x', hex(res).upper()[2:].zfill(2)])))
                else:
                    print("{:<30} {:<10}".format(key, res))
            
        except:
            print('Get Status failed')
            return

def upload_file():
    BLOCKSIZE = 1024
    
    print('Send file upload sequence')
    fileName = input("Enter file name: ")
    
    if len(fileName) > 14:
        print("File name must not exceed 14 chars")
        return
    
    try:
        file = open(fileName, 'rb') 
    except:
        print('file', fileName,'not found')
        return

    device_id_str = input("Enter device ID: ")
    try:
        device_id=int(device_id_str)
    except:
        print('bad device ID')
        return
    
    TypeStr = input("Enter file type (0-To GW or 1-To Dev): ")
    try:
        FileType=int(TypeStr)
    except:
        print('bad File Type')
        return
    if FileType!=0 and FileType!=1:
        print('File type should be 0 or 1')
        return  

        
    fileName = '{0: <15}'.format(fileName)[:15]  #make filename exactly 15-1 bytes
    i=len(fileName)-1
    
    bytesFileName=bytearray(fileName,'utf-8')

    #remove spaces at the end of the file name    
    while i>0:
        if bytesFileName[i]==ord(' ') :
            bytesFileName[i]=0
        i-=1
        
    segment = 0
    
    file_hash = hashlib.md5()
 
    start = timer()
    
    serial_failure = False
    failed_cnt = 0
    
    while True:
        if not serial_failure:
            data = file.read(BLOCKSIZE)
            file_hash.update(data)

            print('sending',len(data),'bytes')

            #parameters:File name – 15 bytes, Fite Type - 1 byte, Segment number – 4 bytes, Data – up to BLOCKSIZE bytes
            #print(data[:20])
            
            message = bytes([0x7]) + bytesFileName + pack('!H', device_id) + bytes([FileType]) + pack('!L', segment) + data
        else:
            print('resending',len(data),'bytes')
        
        SendToSdr(message)
        try:
            status, reply = RecvFromSdr()
            serial_failure = False
        except:
            failed_cnt += 1
            print('failed to get SDR reply (', failed_cnt, ')')
            #return
            serial_failure = True
            continue        # in case of a serial problem: resend the message
        
        #print(status)
        if status!=0:
            print('SDR reply is not OK (',status,')')
            return
        
        segment+=1
        if len(data)<BLOCKSIZE:
            break

    #Send close command (8), Parameters File name: 15 bytes + file Type, MD5 Checksum: 16 bytes

    message = bytes([0x8]) + bytesFileName + pack('!H', device_id) + bytes([FileType]) + file_hash.digest()
    SendToSdr(message)
    try:
        status, reply = RecvFromSdr()
        if status!=0:
            print('SDR reply is not OK (',status,')')
            return
    except:
        print('failed to get SDR reply')
        return

    end = timer()
    print('elapsed time was:',end - start) # Time in seconds, e.g. 5.38091952400282

def download_file():
    BLOCKSIZE = 1024
    total_file_size = 0;
    
    print('Send file download sequence')
    
    fileName = input("Enter file name: ")
    
    if len(fileName) > 14:
        print("File name must not exceed 14 chars")
        return
    
    try:
        file = open(fileName, 'wb') 
    except:
        print('failed to open file', fileName, 'to write')
        return

    TypeStr = input("Enter file type (0-To GW or 1-To Dev): ")
    try:
        file_type=int(TypeStr)
    except:
        print('bad File Type')
        return
    if file_type!=0 and file_type!=1:
        print('File type should be 0 or 1')
        return  

    try:
        device_id = int(input("Enter Device ID: "))
    except:
        print('Bad device ID')
        return
    
    if device_id < 0 or device_id > 0xFFFF:
        print('Invalid device ID')
        return
        
    fileName_15 = '{0: <15}'.format(fileName)[:15]  #make filename exactly 15-1 bytes
    i=len(fileName_15)-1
    
    bytesFileName=bytearray(fileName_15,'utf-8')

    #remove spaces at the end of the file name    
    while i>0:
        if bytesFileName[i]==ord(' ') :
            bytesFileName[i]=0
        i-=1

    start = timer()

    try:
        segment_num = 0
        while True:
            
            max_resends=10
            resends = 0
            while resends < max_resends :
            
                print('segment:', segment_num)
                
                #parameters:File name[15] , Device ID[2], File Type[1], Segment Number[4]
                message = pack('!b15bHBL', 0xa, *bytesFileName, device_id, file_type, segment_num)
                
                SendToSdr(message)
                try:
                    status, reply = RecvFromSdr()
                    break
                except:
                    print('failed to get SDR reply (', resends, ')')
                    resends += 1
                    continue
            
            if resends >= max_resends :
                print('failed to get SDR reply!')
                return
                
            if status!=0:
                print('SDR reply is not OK ('+str(status)+')')
                return
            
#             print('download_file, reply: ', reply)
#             print('len(reply): ', len(reply))
            
            md5_b          = reply[:16]
            segment_data_b = reply[16:]
            
#             print('md5_b:', md5_b)
            md5 = unpack('!16B', md5_b)
            #print '[{}]'.format(', '.join(hex(x) for x in md5))
            print('md5:', *md5)
            
#            print('md5: ', hex(md5[0]), hex(md5[1]), hex(md5[2]), hex(md5[3]), hex(md5[4]), hex(md5[5]), hex(md5[6]), hex(md5[7]), hex(md5[8]),
#                    hex(md5[0]), hex(md5[1]), hex(md5[2]), hex(md5[2]), hex(md5[2]), hex(md5[2]), hex(md5[2]), hex(md5[2]), hex(md5[2]))
            
#             file_hash.update(segment_data)
            
            file.write(segment_data_b)
            
            total_file_size += len(segment_data_b)
            
            if(len(segment_data_b) < BLOCKSIZE): # last segment
                file.close()
                print('downloaded', total_file_size, 'bytes')
                break
                
            segment_num+=1
            
    except:
        raise 'except !!!'
        file.close()
        return

    #Verify file's MD5 is valid
    try:
        file = open(fileName, 'rb') 
    except:
        print('failed to open file', fileName, 'to read')
        return

    file_hash = hashlib.md5()
    data = file.read() 
    file_hash.update(data)
    file.close()
    
    file_md5 = unpack('!16B', file_hash.digest())

    if file_md5 != md5:
        print('MD5 is invalid!')
        print('calculated md5: ', file_md5)
        print('received md5:   ', md5)
    else:
        print('download of file', fileName, 'ended successfully')

def get_config_cmd():
    try:
        print('get Config command')
        buff=bytes([0x31])
        SendToSdr(buff)
        status, reply = RecvFromSdr()
    
        # UTC time - L
        # revolution - d
        # bstar - d
        # eqinc  - d
        # ecc - d
        # mnan  - d
        # argp  - d
        # ascn  - d
        # epoch - d
        # reserved - 59x 
        rec_fmt = '!L8d59x'   # UTC Time, 8 double values, 59 resereved bytes
        result_keys = ['UTC Time', 
                       'mean_motion',
                       'bstar',
                       'eqinc ',
                       'ecc',
                       'mnan ',
                       'argp ',
                       'ascn ',
                       'epoch']
    
        result=unpack(rec_fmt, reply)
        result_dict = dict(zip(result_keys, result))
    
        for key, res in result_dict.items():
            if key == 'UTC Time':
                print(key, ':', str(datetime.fromtimestamp(res)))
            else:
                print(key, ':', result_dict[key])
    except:
        print('failed to get SDR reply')
        return
            
def files_list():
    print('get files list')
    
    TypeStr = input("Enter file type (0-To GW or 1-To Dev): ")
    try:
        file_type=int(TypeStr)
    except:
        print('bad File Type')
        return
    
    if file_type!=0 and file_type!=1:
        print('File type should be 0 or 1')
        return  

    try:
        device_id = int(input("Enter device ID: "))
    except:
        print('Bad device ID')
        return
    
    if device_id < 0 or device_id > 0xFFFF:
        print('Invalid device ID')
        return

    message = pack('!bHB', 0x32, device_id, file_type)
    
    SendToSdr(message)
    
    try:
        status, reply = RecvFromSdr()
    except:
        print('failed to get SDR reply')
        return

    #first get the number of files
    result=unpack_from('!HBh', reply, 0)
    files_num=result[2]
    print('Number of uploaded files: ', files_num)
    
    #now get each of the files name
    offset=5
    for i in range(files_num):
        result=unpack_from('!15s', reply, offset)
        file_name=str(result[0])
        print(i, '. ', file_name.split(r'\x00', 1)[0])
        offset+=15
    
def version():
    print(OBC_VERSION)
    
def quitcmd():
    print('quitting!')
    ser.close()             # close port
    sys.exit(0)

 
def parse(argument, commands_dict):
    func = commands_dict.get(argument)
    if func is not None:
        # Execute the function
        func()
    else:
        print('No such command!')
        return


def main(argv):
    import threading
    global ser
    PORT = "/dev/ttyUSB0"
    start_status_thread = False
    
    print('Running', os.path.basename(__file__))
    
    def status_thread():
        time_init = datetime.now()
        while 1:
            time_delta = (datetime.now()-time_init).total_seconds()
            if time_delta >= 10:
                get_status(auto_get_status=True)
                time_init = datetime.now()
        
    # Command line parser
    parser = argparse.ArgumentParser(description='OBC Simulator')
    parser.add_argument('-p', metavar='<port>', help='serial port (i.e., Linux: /dev/ttyUSB1, Windows: ', required=True)
    parser.add_argument('-a', help='Auto Get Status', required=False, action='store_true')
    args = parser.parse_args()
    
    args_dict = vars(args)
    
    for key, res in args_dict.items():
        if key == 'p':
            PORT = res
            print("PORT is:", PORT)
            continue
        if key == 'a':
            if res == True:
                start_status_thread = True
            continue
            
    # Command : Function
    commands_dict = {
        'nop' :             nop,  #0
        'ka':               ka,  #2
        'config':           config,  #1
        'nogah':            nogah,  #3
        'sband':            sband, #5
        'gen_cmd':          generic,   #6
        'stop':             stop,  #4
        'upload_file':      upload_file,  #7,8
        'download_file':    download_file,
        'quit':             quitcmd,
        'get_status':       get_status,  #30
        'get_conf':         get_config_cmd,  #31
        'files_list':       files_list,   #32
        'shutdown':         shutdowncmd,
        'version':          version}  #9

    commands = commands_dict.keys()

    OBCCompleter = WordCompleter(commands, ignore_case=True)

    try:
        ser = serial.Serial(PORT, 115200, timeout=0.1)  # open serial port, 2 seconds timeout 
        print('Opened serial port', PORT)
    except AttributeError as err:
        print("Attribute Error: {0}".format(err))
    except:
        print("Failed to open serial port", PORT, sys.exc_info()[0])
        sys.exit(0)
 
    if start_status_thread:
        print("Auto Get Status is enabled")
        threading.Thread(target=status_thread, daemon=True).start()
    else:
        print("Auto Get Status is disabled")
    
    while 1:
        try:
            user_input = prompt('OBC>',
                                history=FileHistory('history.txt'),
                                auto_suggest=AutoSuggestFromHistory(),
                                completer=OBCCompleter,
                                )
            #print(user_input)
            parse(user_input, commands_dict)
            # Get the function from switcher dictionary
        except KeyboardInterrupt:
            quitcmd()
        except SystemExit as e:
            sys.exit(e)
        except:
            raise "Failed!!!"
    
    quitcmd()

if __name__ == '__main__':
    main(sys.argv)
