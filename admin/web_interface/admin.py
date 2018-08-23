from django.contrib import admin
from .models import Customer, Item, CustomerItem, Location

class CustomerAdmin(admin.ModelAdmin):
	list_display = ('name', 'email', 'password', 'active')


class ItemAdmin(admin.ModelAdmin):
	list_display = ('description',)


class CustomerItemAdmin(admin.ModelAdmin):
	list_display = ('customer', 'item')


class LocationAdmin(admin.ModelAdmin):
	list_display = ('customer', 'location')


admin.site.register(Customer, CustomerAdmin)
admin.site.register(Item, ItemAdmin)
admin.site.register(CustomerItem, CustomerItemAdmin)
admin.site.register(Location, LocationAdmin)
