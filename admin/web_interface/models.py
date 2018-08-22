from django.db import models

class Customer(models.Model):
	name = models.CharField(max_length=200, default='')
	email = models.CharField(max_length=200, default='')
	password = models.CharField(max_length=200, default='')
	active = models.IntegerField(default=1)

	class Meta:
		db_table = 'customer'
