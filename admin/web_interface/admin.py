from django.contrib import admin
from .models import Customer, Item, CustomerItem, Location, StandingOrder

class CustomerAdmin(admin.ModelAdmin):
	list_display = ('name', 'email', 'password', 'active')


class ItemAdmin(admin.ModelAdmin):
	list_display = ('description',)


class CustomerItemAdmin(admin.ModelAdmin):
	list_display = ('customer', 'item')


class LocationAdmin(admin.ModelAdmin):
	list_display = ('customer', 'location')


class StandingOrderAdmin(admin.ModelAdmin):
	list_display = ('customer', 'day_of_week', 'location', 'item', 'qte', 'active')


admin.site.register(Customer, CustomerAdmin)
admin.site.register(Item, ItemAdmin)
admin.site.register(CustomerItem, CustomerItemAdmin)
admin.site.register(Location, LocationAdmin)
admin.site.register(StandingOrder, StandingOrderAdmin)
