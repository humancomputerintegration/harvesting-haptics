"""
UART Service
-------------
An example showing how to write a simple program using the Nordic Semiconductor
(nRF) UART service.
"""

import asyncio
import sys

from bleak import BleakScanner, BleakClient
from bleak.backends.scanner import AdvertisementData
from bleak.backends.device import BLEDevice

from pythonosc import udp_client
from pythonosc import osc_server
from pythonosc import dispatcher

import threading


# OSC address
# ================== #
ip = "10.150.30.79"
# ip = "169.254.0.1"
# ip = "192.168.0.102"
port_server = 5006 # processing -> this
port_client = 5005 # this -> processing
# ================== #

to_send_ble = False
to_send_cmd = 0

# open osc client (speak to unity)
oscclient = udp_client.SimpleUDPClient(ip, port_client)
print("connected to OSC server at "+ip+":"+str(port_client))

def ble_handler(unused_addr, osc_num):
    global to_send_ble
    global to_send_cmd
    print('osc > ble ' + str(osc_num))
    to_send_cmd = osc_num
    to_send_ble = True

dispatcher = dispatcher.Dispatcher()
dispatcher.map("/ble", ble_handler)

# open osc server (listen from unity)
server = osc_server.ThreadingOSCUDPServer((ip, port_server), dispatcher)
server_thread = threading.Thread(target=server.serve_forever)
server_thread.start()
print("open an OSC server at "+ip+":"+str(port_server))


UART_SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
UART_RX_CHAR_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
UART_TX_CHAR_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

# All BLE devices have MTU of at least 23. Subtracting 3 bytes overhead, we can
# safely send 20 bytes at a time to any device supporting this service.
UART_SAFE_SIZE = 20

# on macbook
# ADDR = "2280DFF7-34F8-4C90-992C-FEFA64153CD5"
# ADDR = "B43B06D8-31D9-4365-9C61-1AF3003B84CB"
# ADDR = "F15B2376-1B84-43DF-85F2-84B89BEEC7FC"
# ADDR = "BC2FB908-3969-4535-8F6B-80D0ABB57DAD"
ADDR = "2160901D-5C76-4B7D-87CE-A248C0DE24CC"

oscclient.send_message('/disconnected', 0);

async def uart_terminal(addr):
    global to_send_ble
    global to_send_cmd


    def handle_disconnect(_: BleakClient):
        print("disconnected...")
        oscclient.send_message('/disconnected', 0);
        # cancelling all tasks effectively ends the program
        for task in asyncio.all_tasks():
            task.cancel()

    def handle_rx(_: int, data: bytearray):
        data_int = 0
        try:
            data_int = int(data)
            print("received:", int(data))
            oscclient.send_message('/power', int(data))
        except:
            pass

    print("scan...")
    device = None 
    while not device:
        device = await BleakScanner.find_device_by_address(addr, timeout=20.0)

    print("found...")

    async with BleakClient(addr, disconnected_callback=handle_disconnect) as client:
        try:
            await client.start_notify(UART_TX_CHAR_UUID, handle_rx)

            loop = asyncio.get_event_loop()
            reader = asyncio.StreamReader()
            protocol = asyncio.StreamReaderProtocol(reader)
            await loop.connect_read_pipe(lambda: protocol, sys.stdin)

            print("Connected...")
            oscclient.send_message('/connected', 0);
            s = '0' + '\n'
            data = s.encode()
            await client.write_gatt_char(UART_RX_CHAR_UUID, data)
            print("sent:", data)

            # while True:
            while client.is_connected:

                await asyncio.sleep(0.1)

                if to_send_ble:
                    s = str(to_send_cmd) + '\n'
                    data = s.encode()
                    await client.write_gatt_char(UART_RX_CHAR_UUID, data)
                    print("sent:", data)
                    to_send_ble = False
        except AttributeError as exception:
            print("ahhh inside AttributeError...")
        except asyncio.CancelledError:
            print("ahhh inside CancelledError...")
        except asyncio.TimeoutError:
            print("ahhh inside TimeoutError...")
        except asyncio.InvalidStateError:
            print("ahhh inside InvalidStateError...")
        except Exception as e:
            print("ahhh inside...")


loop = asyncio.get_event_loop()

# It is important to use asyncio.run() to get proper cleanup on KeyboardInterrupt.
# This was introduced in Python 3.7. If you need it in Python 3.6, you can copy
# it from https://github.com/python/cpython/blob/3.7/Lib/asyncio/runners.py
while True:
    try:
        print("asyncio run...")
        # asyncio.run(uart_terminal(ADDR))
        loop = asyncio.get_event_loop()
        loop.run_until_complete(uart_terminal(ADDR))
    except AttributeError as exception:
        print("ahhh outside AttributeError...")
    except asyncio.CancelledError:
        print("ahhh outside CancelledError...")
    except asyncio.TimeoutError:
        print("ahhh outside TimeoutError...")
    except asyncio.InvalidStateError:
        print("ahhh outside InvalidStateError...")
    except Exception as e:
        print("ahhh outside...")
