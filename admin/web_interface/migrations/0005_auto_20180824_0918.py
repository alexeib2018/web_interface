# Generated by Django 2.1 on 2018-08-24 09:18

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('web_interface', '0004_standingorder'),
    ]

    operations = [
        migrations.AlterField(
            model_name='item',
            name='id',
            field=models.IntegerField(primary_key=True, serialize=False),
        ),
    ]