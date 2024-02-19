import logging
import threading
import time


import sys
print(sys.version)



i = 0
done = 0
f = 0
def thread_functionx(name):
    logging.info("Thread %s: starting", name)
    global i
    global done
    while (done==0):
     i = i+1
     print(f"i={i} done={done}")
     time.sleep(2)

    logging.info("Thread %s: finishing", name)

def thread_functiony(name):
    global done
    logging.info("Thread %s: starting", name)
    print ("press any key to finish")
    x = input()
    done = 1
    logging.info("Thread %s: finishing", name)

if __name__ == "__main__":
    f = open("demofile.txt",'w')

    y = threading.Thread(target=thread_functiony, args=(2,))
    y.start()

    i = 1
    while (done==0):
     i = i+1
     print(f"i={i} done={done}")
     f.write(f"i={i} done={done}")
     time.sleep(1)

    f.close()
    # logging.info("Main    : before creating thread x")
    # x = threading.Thread(target=thread_functionx, args=(1,))
    # logging.info("Main    : before running thread x")
    # x.start()



    logging.info("Main    : wait for the thread to finish")
    # x.join()
    logging.info("Main    : all done")