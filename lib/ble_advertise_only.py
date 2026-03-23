import asyncio
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, dbus_property, PropertyAccess
from dbus_next import Variant

SERVICE_UUID = "12345678-1234-5678-1234-56789abcdef0"

class Advertisement(ServiceInterface):
    def __init__(self):
        super().__init__("org.bluez.LEAdvertisement1")
        self.path = "/com/radar/adv0"

    def get_path(self):
        return self.path

    @dbus_property(access=PropertyAccess.READ)
    def Type(self):
        return "peripheral"

    @dbus_property(access=PropertyAccess.READ)
    def LocalName(self):
        return "RadarRangers"

    @dbus_property(access=PropertyAccess.READ)
    def ServiceUUIDs(self):
        return [SERVICE_UUID]

    @method()
    def Release(self):
        pass

async def main():
    bus = await MessageBus(system=True).connect()

    intro = await bus.introspect("org.bluez", "/org/bluez/hci0")
    obj = bus.get_proxy_object("org.bluez", "/org/bluez/hci0", intro)
    adv_mgr = obj.get_interface("org.bluez.LEAdvertisingManager1")

    adv = Advertisement()
    bus.export(adv.get_path(), adv)

    await adv_mgr.call_register_advertisement(adv.get_path(), {})
    print("BLE advertising as RadarRangers")

    await asyncio.Event().wait()

asyncio.run(main())
