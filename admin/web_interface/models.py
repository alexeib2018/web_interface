from django.db import models


class Customer(models.Model):
	name = models.CharField(max_length=200, default='')
	email = models.CharField(max_length=200, default='')
	password = models.CharField(max_length=200, default='')
	active = models.IntegerField(default=1)

	def __str__(self):
		return '%s <%s>' % (self.name, self.email)

	class Meta:
		db_table = 'customer'


class Item(models.Model):
	description = models.CharField(max_length=200, default='')

	def __str__(self):
		return self.description

	class Meta:
		db_table = 'items'


class CustomerItem(models.Model):
	customer = models.ForeignKey(Customer, on_delete=models.CASCADE)
	item = models.ForeignKey(Item, on_delete=models.CASCADE)

	class Meta:
		db_table = 'customer_items'
