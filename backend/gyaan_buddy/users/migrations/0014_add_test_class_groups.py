# Generated manually for multi-class test support

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0013_alter_testmodulechapter_id'),
    ]

    operations = [
        migrations.AlterField(
            model_name='test',
            name='class_group',
            field=models.ForeignKey(
                blank=True,
                help_text='Primary class (first selected); used for backward compatibility. Use class_groups for multi-class tests.',
                null=True,
                on_delete=models.deletion.CASCADE,
                related_name='tests',
                to='users.class',
            ),
        ),
        migrations.AddField(
            model_name='test',
            name='class_groups',
            field=models.ManyToManyField(
                blank=True,
                help_text='Classes this test is assigned to (can be multiple). When set, class_group is set to the first class.',
                related_name='test_assignments',
                to='users.class',
            ),
        ),
    ]
