#!/usr/bin/env python3

import json
import threading

from gi.repository import GLib
import dbus
import dbus.exceptions
import dbus.mainloop.glib
import dbus.service

import read_vitals

#uuid
SERVICE_UUID = "12345678-1234-1234-1234-1234567890ab"
HEART_WAVE_UUID = "12345678-1234-1234-1234-1234567890ae"
BREATH_WAVE_UUID = "12345678-1234-1234-1234-1234567890af"
VITALS_LINE_UUID = "12345678-1234-1234-1234-1234567890b0"
COMMAND_UUID = "12345678-1234-1234-1234-1234567890b1"

DEVICE_NAME = "RadarRangers"

BLUEZ_SERVICE_NAME = "org.bluez"
GATT_MANAGER_IFACE = "org.bluez.GattManager1"
LE_ADVERTISING_MANAGER_IFACE = "org.bluez.LEAdvertisingManager1"
DBUS_OM_IFACE = "org.freedesktop.DBus.ObjectManager"
GATT_SERVICE_IFACE = "org.bluez.GattService1"
GATT_CHRC_IFACE = "org.bluez.GattCharacteristic1"
LE_ADVERTISEMENT_IFACE = "org.bluez.LEAdvertisement1"
PROP_IFACE = "org.freedesktop.DBus.Properties"

streaming_enabled = False

# Helpers
def find_adapter(bus):
    obj = bus.get_object(BLUEZ_SERVICE_NAME, "/")
    om = dbus.Interface(obj, DBUS_OM_IFACE)
    objects = om.GetManagedObjects()

    for path, ifaces in objects.items():
        if LE_ADVERTISING_MANAGER_IFACE in ifaces and GATT_MANAGER_IFACE in ifaces:
            return path

    raise Exception("No BLE adapter found.")


def dbus_array(bytes_data: bytes):
    return dbus.Array([dbus.Byte(b) for b in bytes_data], signature="y")

# Advertisement
class Advertisement(dbus.service.Object):
    PATH_BASE = "/org/bluez/example/advertisement"

    def __init__(self, bus, index):
        self.path = self.PATH_BASE + str(index)
        self.bus = bus
        self.ad_type = "peripheral"
        self.local_name = DEVICE_NAME
        self.service_uuids = [SERVICE_UUID]
        super().__init__(bus, self.path)

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def get_properties(self):
        return {
            LE_ADVERTISEMENT_IFACE: {
                "Type": self.ad_type,
                "LocalName": self.local_name,
                "ServiceUUIDs": dbus.Array(self.service_uuids, signature="s"),
                "IncludeTxPower": dbus.Boolean(True),
            }
        }

    @dbus.service.method(DBUS_OM_IFACE, out_signature="a{oa{sa{sv}}}")
    def GetManagedObjects(self):
        return {self.path: self.get_properties()}

    @dbus.service.method(PROP_IFACE, in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        return self.get_properties()[interface][prop]

    @dbus.service.method(PROP_IFACE, in_signature="ssv")
    def Set(self, interface, prop, value):
        raise dbus.exceptions.DBusException(
            "org.bluez.Error.NotPermitted",
            "Not permitted",
        )

    @dbus.service.method(PROP_IFACE, in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        return self.get_properties().get(interface, {})

    @dbus.service.method(LE_ADVERTISEMENT_IFACE, in_signature="", out_signature="")
    def Release(self):
        print("Advertisement released")

# GATT Application / Service / Characteristic
class Application(dbus.service.Object):
    def __init__(self, bus):
        self.path = "/org/bluez/example/app"
        self.services = []
        super().__init__(bus, self.path)

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_service(self, service):
        self.services.append(service)

    @dbus.service.method(DBUS_OM_IFACE, out_signature="a{oa{sa{sv}}}")
    def GetManagedObjects(self):
        response = {}
        for service in self.services:
            response[service.get_path()] = service.get_properties()
            for chrc in service.characteristics:
                response[chrc.get_path()] = chrc.get_properties()
        return response


class Service(dbus.service.Object):
    def __init__(self, bus, index, uuid, primary=True):
        self.path = f"/org/bluez/example/service{index}"
        self.bus = bus
        self.uuid = uuid
        self.primary = primary
        self.characteristics = []
        super().__init__(bus, self.path)

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_characteristic(self, chrc):
        self.characteristics.append(chrc)

    def get_properties(self):
        return {
            GATT_SERVICE_IFACE: {
                "UUID": self.uuid,
                "Primary": dbus.Boolean(self.primary),
            }
        }


class Characteristic(dbus.service.Object):
    def __init__(self, bus, index, uuid, flags, service):
        self.path = service.path + f"/char{index}"
        self.bus = bus
        self.uuid = uuid
        self.flags = flags
        self.service = service
        self.notifying = False
        self.value = dbus.Array([], signature="y")
        super().__init__(bus, self.path)

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def get_properties(self):
        return {
            GATT_CHRC_IFACE: {
                "UUID": self.uuid,
                "Service": self.service.get_path(),
                "Flags": dbus.Array(self.flags, signature="s"),
                "Descriptors": dbus.Array([], signature="o"),
                "Value": self.value,
            }
        }

    @dbus.service.method(PROP_IFACE, in_signature="ss", out_signature="v")
    def Get(self, interface, prop):
        return self.get_properties()[interface][prop]

    @dbus.service.method(PROP_IFACE, in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        return self.get_properties().get(interface, {})

    @dbus.service.method(GATT_CHRC_IFACE, in_signature="a{sv}", out_signature="ay")
    def ReadValue(self, options):
        print(f"[READ] {self.uuid}")
        return self.value

    @dbus.service.method(GATT_CHRC_IFACE, in_signature="", out_signature="")
    def StartNotify(self):
        self.notifying = True
        print(f"[START NOTIFY] {self.uuid}")

    @dbus.service.method(GATT_CHRC_IFACE, in_signature="", out_signature="")
    def StopNotify(self):
        self.notifying = False
        print(f"[STOP NOTIFY] {self.uuid}")

    def set_value_and_notify(self, raw_bytes: bytes):
        self.value = dbus_array(raw_bytes)
        print(f"[NOTIFY TRY] uuid={self.uuid} notifying={self.notifying}")

        if self.notifying:
            self.PropertiesChanged(
                GATT_CHRC_IFACE,
                {"Value": self.value},
                [],
            )
            print(f"[NOTIFY SENT] uuid={self.uuid}")
        else:
            print(f"[NOTIFY SKIPPED] uuid={self.uuid}")

    @dbus.service.signal(PROP_IFACE, signature="sa{sv}as")
    def PropertiesChanged(self, interface, changed, invalidated):
        pass

class CommandCharacteristic(Characteristic):
    def __init__(self, bus, index, service):
        super().__init__(bus, index, COMMAND_UUID, ["read", "write"], service)

    @dbus.service.method(GATT_CHRC_IFACE, in_signature="aya{sv}", out_signature="")
    def WriteValue(self, value, options):
        global streaming_enabled

        cmd = bytes(value).decode("utf-8").strip().lower()
        print(f"[CMD] received: {cmd}")

        if cmd == "start":
            streaming_enabled = True
            print("[CMD] start received -> streaming_enabled=True")
        elif cmd == "stop":
            streaming_enabled = False
            print("[CMD] stop received -> streaming_enabled=False")
        elif cmd == "restart":
            streaming_enabled = True
            print("[CMD] restart received -> streaming_enabled=True")
        else:
            print("[CMD] unknown command")

# Main


def main():
    global streaming_enabled

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    adapter_path = find_adapter(bus)
    print("Using adapter:", adapter_path)

    ad_manager = dbus.Interface(
        bus.get_object(BLUEZ_SERVICE_NAME, adapter_path),
        LE_ADVERTISING_MANAGER_IFACE,
    )
    adv = Advertisement(bus, 0)
    ad_manager.RegisterAdvertisement(
        adv.get_path(),
        {},
        reply_handler=lambda: print("Advertisement registered"),
        error_handler=lambda e: print("Adv register error:", e),
    )

    app = Application(bus)
    svc = Service(bus, 0, SERVICE_UUID, True)

    heart_wave_char = Characteristic(bus, 0, HEART_WAVE_UUID, ["read", "notify"], svc)
    breath_wave_char = Characteristic(bus, 1, BREATH_WAVE_UUID, ["read", "notify"], svc)
    vitals_line_char = Characteristic(bus, 2, VITALS_LINE_UUID, ["read", "notify"], svc)
    command_char = CommandCharacteristic(bus, 3, svc)

    svc.add_characteristic(heart_wave_char)
    svc.add_characteristic(breath_wave_char)
    svc.add_characteristic(vitals_line_char)
    svc.add_characteristic(command_char)
    app.add_service(svc)

    gatt_manager = dbus.Interface(
        bus.get_object(BLUEZ_SERVICE_NAME, adapter_path),
        GATT_MANAGER_IFACE,
    )
    gatt_manager.RegisterApplication(
        app.get_path(),
        {},
        reply_handler=lambda: print("GATT app registered"),
        error_handler=lambda e: print("GATT register error:", e),
    )

    def on_vitals(hr, br, presence_flag, frame_number, vitals_range_bin, ai_state):
        if not streaming_enabled:
            return

        print(f"[BLE SEND] HR={hr} BR={br} P={presence_flag} AI={ai_state}")

        payload = {
            "hr": float(hr),
            "br": float(br),
            "presence": int(presence_flag),
            "ai_state": str(ai_state),
        }

        msg = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        vitals_line_char.set_value_and_notify(msg)

    print("[RADAR] starting vitals loop thread")
    threading.Thread(
        target=read_vitals.run_vitals_loop,
        args=(on_vitals,),
        kwargs={"log_csv": False},
        daemon=True,
    ).start()

    print("BLE radar server running...")
    mainloop = GLib.MainLoop()
    mainloop.run()


if __name__ == "__main__":
    main()