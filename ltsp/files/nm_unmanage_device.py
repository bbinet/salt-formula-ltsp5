#!/usr/bin/python3
"""
Control NetworkManager from dbus to unmanage a device

The Python version of the example at
https://forums.resin.io/t/rpi-3-access-point-hostapd-disconnects-after-a-few-minutes/1987/4

On resin.io devices need to set the system dbus address:
DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket
"""
import sys
import os

import dbus


os.environ["DBUS_SYSTEM_BUS_ADDRESS"] = "unix:path=/host/run/dbus/system_bus_socket"

device = sys.argv[1]
bus = dbus.SystemBus()

nm_proxy = bus.get_object('org.freedesktop.NetworkManager', '/org/freedesktop/NetworkManager')
nm = dbus.Interface(nm_proxy, dbus_interface='org.freedesktop.NetworkManager')

for device_obj_path in nm.GetDevices():
    device_proxy = bus.get_object('org.freedesktop.NetworkManager', device_obj_path)
    device = dbus.Interface(device_proxy, dbus_interface='org.freedesktop.DBus.Properties')
    #print(device.Get('org.freedesktop.NetworkManager.Device', 'Interface'))
    #print(device.Get('org.freedesktop.NetworkManager.Device', 'Managed'))
    if device.Get('org.freedesktop.NetworkManager.Device', 'Interface') == device:
        device.Set('org.freedesktop.NetworkManager.Device', 'Managed', False)
