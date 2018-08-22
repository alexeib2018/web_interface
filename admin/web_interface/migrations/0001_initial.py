# Generated by Django 2.1 on 2018-08-22 10:26

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Customer',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(default='', max_length=200)),
                ('email', models.CharField(default='', max_length=200)),
                ('password', models.CharField(default='', max_length=200)),
                ('active', models.IntegerField(default=1)),
            ],
            options={
                'db_table': 'customer',
            },
        ),
    ]
